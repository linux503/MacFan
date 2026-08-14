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
    var statusMessage: String = "正在探测风扇…"
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
        self.isPrivileged = geteuid() == 0
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
                statusMessage = "实机控制已启用（管理员）"
            } else if isLiveHardware {
                statusMessage = "已读到真实风扇，但写入需要管理员权限"
                lastError = "点击下方按钮，输入密码后以管理员身份启动，才能真正调速。"
            } else {
                statusMessage = "未读到 SMC 风扇，当前为预览数据"
            }
        } catch {
            lastError = error.localizedDescription
            statusMessage = "初始化失败"
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
                statusMessage = "已恢复系统自动温控"
            case .maximum:
                try await controller.setMaximum()
                activeScene = nil
                statusMessage = "全部风扇已设为最大转速"
            case .manual:
                statusMessage = "手动模式：拖动滑杆调节单风扇"
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
            statusMessage = "已设定 \(id) → \(Int(rpm)) RPM"
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
        guard let exe = Bundle.main.executableURL?.path else {
            lastError = "找不到可执行文件路径"
            return
        }
        let escaped = exe.replacingOccurrences(of: "'", with: "'\\''")
        let appleScript = "do shell script \"'\\(escaped)' >/dev/null 2>&1 &\" with administrator privileges"
        var error: NSDictionary?
        if let script = NSAppleScript(source: appleScript) {
            script.executeAndReturnError(&error)
            if let error {
                lastError = error[NSAppleScript.errorMessage] as? String ?? "提权失败"
                return
            }
            NSApp.terminate(nil)
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
                statusMessage = "场景「\(scene.name)」· 目标 \(Int(percent * 100))%"
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
