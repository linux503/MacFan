import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class FanDashboardViewModel {
    var fans: [FanInfo] = []
    var thermal: ThermalReading = ThermalReading(cpuCelsius: 0, gpuCelsius: 0, enclosureCelsius: 0)
    var history: [ThermalReading] = []
    var mode: FanControlMode = .manual
    var scenes: [FanScene] = FanScene.builtIn
    var selectedSceneID: FanScene.ID?
    var activeScene: FanScene?
    var appLinkEnabled: Bool = true
    var scheduleEnabled: Bool = true
    var statusMessage: String = L10n.t("status.probing")
    var lastError: String?
    var machine: MachineProfile = MachineIdentity.profile()
    var isLiveHardware: Bool = false
    var isPrivileged: Bool = false
    var isBusy: Bool = false

    private let controller: AdaptiveFanController
    private let appLink = AppLinkMonitor()
    private var tickTask: Task<Void, Never>?

    init(controller: AdaptiveFanController = AdaptiveFanController()) {
        self.controller = controller
        self.selectedSceneID = scenes.first(where: { $0.kind == .silentOffice })?.id
        self.isPrivileged = geteuid() == 0 || SMCHelperClient.isReady
    }

    var selectedScene: FanScene? {
        scenes.first(where: { $0.id == selectedSceneID })
    }

    var severity: ThermalSeverity {
        ThermalSeverity(celsius: thermal.peakCelsius)
    }

    var architectureBadge: String {
        "\(machine.architecture.rawValue) · \(machine.modelName)"
    }

    var needsAdminToControl: Bool {
        isLiveHardware && !isPrivileged
    }

    func refreshLocalizedStatus() {
        if !isLiveHardware {
            fans = fans.map { fan in
                var copy = fan
                copy.name = SimulatedFanHardware.previewName(id: fan.id, architecture: machine.architecture)
                return copy
            }
        }

        scenes = scenes.map { scene in
            var copy = scene
            copy.name = scene.kind.title
            return copy
        }
        if let active = activeScene, let updated = scenes.first(where: { $0.id == active.id }) {
            activeScene = updated
        }

        if isBusy {
            statusMessage = L10n.t("admin.authorizing")
            lastError = L10n.t("admin.passwordHint")
            return
        }

        if isLiveHardware && isPrivileged {
            switch mode {
            case .automatic:
                statusMessage = L10n.t("status.auto")
            case .maximum:
                statusMessage = L10n.t("status.max")
            case .manual:
                statusMessage = L10n.t("status.manual")
            case .scene:
                if let scene = activeScene {
                    let percent = scene.fanPercent(for: thermal.peakCelsius)
                    statusMessage = String(
                        format: L10n.t("status.scene"),
                        scene.kind.title,
                        Int(percent * 100)
                    )
                } else {
                    statusMessage = L10n.t("status.liveAdmin")
                }
            }
            if !needsAdminToControl {
                lastError = nil
            }
        } else if isLiveHardware {
            statusMessage = L10n.t("status.liveNeedAdmin")
            lastError = L10n.t("error.needAdminHint")
        } else if fans.isEmpty {
            statusMessage = L10n.t("status.probing")
            lastError = nil
        } else {
            statusMessage = L10n.t("status.preview")
            lastError = nil
        }
    }

    func start() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            await self?.bootstrap()
            while let self, !Task.isCancelled {
                await self.tick()
                try? await Task.sleep(for: .seconds(1.2))
            }
        }
    }

    func stop() {
        tickTask?.cancel()
        tickTask = nil
    }

    func bootstrap() async {
        isBusy = true
        defer { isBusy = false }
        controller.refreshPrivilege()
        isPrivileged = controller.isPrivileged
        do {
            fans = try await controller.discoverFans()
            isLiveHardware = controller.usingLiveSMC
            thermal = try await controller.readThermals()
            if isLiveHardware && isPrivileged {
                statusMessage = L10n.t("status.liveAdmin")
            } else if isLiveHardware {
                statusMessage = L10n.t("status.liveNeedAdmin")
                lastError = L10n.t("error.needAdminHint")
            } else {
                statusMessage = L10n.t("status.preview")
            }
        } catch {
            lastError = error.localizedDescription
            statusMessage = L10n.t("status.initFailed")
        }
    }

    func tick() async {
        do {
            thermal = try await controller.readThermals()
            history.append(thermal)
            if history.count > 90 { history.removeFirst(history.count - 90) }
            fans = try await controller.discoverFans()
            isLiveHardware = controller.usingLiveSMC
            if mode == .scene, isPrivileged, isLiveHardware {
                await applySceneLogic(force: false)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func selectMode(_ newMode: FanControlMode) async {
        mode = newMode
        lastError = nil
        do {
            switch newMode {
            case .automatic:
                try await controller.setAutomatic()
                activeScene = nil
                statusMessage = L10n.t("status.auto")
            case .maximum:
                try await controller.setMaximum()
                activeScene = nil
                statusMessage = L10n.t("status.max")
            case .manual:
                statusMessage = L10n.t("status.manual")
            case .scene:
                await applySceneLogic(force: true)
            }
            fans = try await controller.discoverFans()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func setFanRPM(id: String, rpm: Double) async {
        mode = .manual
        do {
            try await controller.setManual(fanID: id, rpm: rpm)
            fans = try await controller.discoverFans()
            if let index = fans.firstIndex(where: { $0.id == id }) {
                fans[index].targetRPM = rpm
                fans[index].isManual = true
            }
            statusMessage = String(format: L10n.t("status.fanSet"), id, Int(rpm))
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func selectScene(_ scene: FanScene) async {
        selectedSceneID = scene.id
        mode = .scene
        await applySceneLogic(force: true)
    }

    func relaunchAsAdministrator() {
        if isPrivileged {
            statusMessage = L10n.t("status.liveAdmin")
            lastError = nil
            return
        }

        statusMessage = L10n.t("admin.authorizing")
        lastError = L10n.t("admin.passwordHint")
        isBusy = true
        NSApp.activate(ignoringOtherApps: true)

        Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.detached(priority: .userInitiated) {
                    try PrivilegedElevator.startHelper()
                }.value
                controller.refreshPrivilege()
                isPrivileged = controller.isPrivileged
                if isPrivileged {
                    lastError = nil
                    statusMessage = L10n.t("status.liveAdmin")
                    // Re-apply current mode so the first click actually writes SMC.
                    await selectMode(mode)
                } else {
                    lastError = L10n.t("admin.helperNotReady")
                    statusMessage = L10n.t("admin.failed")
                }
            } catch {
                lastError = error.localizedDescription
                statusMessage = L10n.t("admin.failed")
                let alert = NSAlert()
                alert.messageText = L10n.t("admin.title")
                alert.informativeText = error.localizedDescription + "\n\n" + L10n.t("admin.passwordHint")
                alert.alertStyle = .warning
                alert.addButton(withTitle: L10n.t("ok"))
                alert.runModal()
            }
            isBusy = false
        }
    }

    private func applySceneLogic(force: Bool) async {
        var scene = selectedScene

        if scheduleEnabled, let scheduled = appLink.activeScheduledScene(from: scenes) {
            scene = scheduled
        }
        if appLinkEnabled, let linked = appLink.matchedScene(from: scenes) {
            scene = linked
        }

        guard let scene else { return }
        let changed = activeScene?.id != scene.id
        activeScene = scene
        selectedSceneID = scene.id

        let percent = scene.fanPercent(for: thermal.peakCelsius)
        do {
            for fan in fans {
                let rpm = fan.minRPM + (fan.maxRPM - fan.minRPM) * percent
                try await controller.setManual(fanID: fan.id, rpm: rpm)
            }
            fans = try await controller.discoverFans()
            if force || changed {
                statusMessage = String(
                    format: L10n.t("status.scene"),
                    scene.kind.title,
                    Int(percent * 100)
                )
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
