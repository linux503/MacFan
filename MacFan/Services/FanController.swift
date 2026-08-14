import Foundation
import IOKit

protocol FanControlling: AnyObject {
    var isPrivileged: Bool { get }
    var usingLiveSMC: Bool { get }
    func discoverFans() async throws -> [FanInfo]
    func readThermals() async throws -> ThermalReading
    func setAutomatic() async throws
    func setMaximum() async throws
    func setManual(fanID: String, rpm: Double) async throws
}

enum FanControlError: LocalizedError {
    case unsupported
    case privilegeRequired
    case fanNotFound(String)
    case smcUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return L10n.t("error.unsupported")
        case .privilegeRequired:
            return L10n.t("error.privilege")
        case .fanNotFound(let id):
            return String(format: L10n.t("error.fanMissing"), id)
        case .smcUnavailable(let detail):
            return String(format: L10n.t("error.smc"), detail)
        }
    }
}

/// Live SMC when available; simulation only as last-resort fallback for UI preview.
final class AdaptiveFanController: FanControlling, @unchecked Sendable {
    private let architecture: ChipArchitecture
    private let simulator: SimulatedFanHardware
    private let smc = SMCClient.shared
    private(set) var isPrivileged: Bool
    private(set) var usingLiveSMC: Bool = false

    init(architecture: ChipArchitecture = .current) {
        self.architecture = architecture
        self.simulator = SimulatedFanHardware(architecture: architecture)
        self.isPrivileged = geteuid() == 0 || SMCHelperClient.isReady
    }

    func refreshPrivilege() {
        isPrivileged = geteuid() == 0 || SMCHelperClient.isReady
    }

    func discoverFans() async throws -> [FanInfo] {
        if let live = try? smc.readFans(), !live.isEmpty {
            usingLiveSMC = true
            return live
        }
        usingLiveSMC = false
        return await simulator.discoverFans()
    }

    func readThermals() async throws -> ThermalReading {
        if usingLiveSMC, let reading = smc.readThermals() {
            return reading
        }
        return await simulator.readThermals()
    }

    func setAutomatic() async throws {
        try await ensureLiveWritable()
        if geteuid() == 0 {
            let fans = try smc.readFans()
            for index in fans.indices {
                try smc.setAutomatic(fanIndex: index)
            }
        } else {
            try SMCHelperClient.send("AUTO")
        }
    }

    func setMaximum() async throws {
        try await ensureLiveWritable()
        if geteuid() == 0 {
            let fans = try smc.readFans()
            for index in fans.indices {
                try smc.setMaximum(fanIndex: index)
            }
        } else {
            try SMCHelperClient.send("MAX")
        }
    }

    func setManual(fanID: String, rpm: Double) async throws {
        try await ensureLiveWritable()
        guard let index = smc.fanIndex(from: fanID) else {
            throw FanControlError.fanNotFound(fanID)
        }
        if geteuid() == 0 {
            try smc.setManual(fanIndex: index, rpm: rpm)
        } else {
            try SMCHelperClient.send("SET \(index) \(Int(rpm.rounded()))")
        }
    }

    private func ensureLiveWritable() async throws {
        refreshPrivilege()
        if !usingLiveSMC {
            // Try once more in case SMC became available.
            if let live = try? smc.readFans(), !live.isEmpty {
                usingLiveSMC = true
            }
        }
        guard usingLiveSMC else {
            throw FanControlError.smcUnavailable(L10n.t("error.noLiveFans"))
        }
        guard isPrivileged else {
            throw FanControlError.privilegeRequired
        }
    }
}

/// Preview-only model when SMC fans cannot be enumerated.
actor SimulatedFanHardware {
    private let architecture: ChipArchitecture
    private var fans: [FanInfo]

    init(architecture: ChipArchitecture) {
        self.architecture = architecture
        self.fans = Self.makeFans(architecture: architecture)
    }

    static func previewName(id: String, architecture: ChipArchitecture) -> String {
        switch architecture {
        case .appleSilicon:
            switch id {
            case "F0": return L10n.t("fan.leftExhaust")
            case "F1": return L10n.t("fan.rightExhaust")
            default: break
            }
        case .intel:
            switch id {
            case "F0": return L10n.t("fan.intake")
            case "F1": return L10n.t("fan.cpu")
            case "F2": return L10n.t("fan.exhaust")
            default: break
            }
        case .unknown:
            if id == "F0" { return L10n.t("fan.system") }
        }
        if id.hasPrefix("F"), let index = Int(id.dropFirst()) {
            return String(format: L10n.t("fan.index"), index)
        }
        return id
    }

    private static func makeFans(architecture: ChipArchitecture) -> [FanInfo] {
        switch architecture {
        case .appleSilicon:
            return [
                FanInfo(id: "F0", name: "F0", currentRPM: 0, targetRPM: 0, minRPM: 1200, maxRPM: 6150, isManual: false),
                FanInfo(id: "F1", name: "F1", currentRPM: 0, targetRPM: 0, minRPM: 1200, maxRPM: 6150, isManual: false)
            ]
        case .intel:
            return [
                FanInfo(id: "F0", name: "F0", currentRPM: 2100, targetRPM: 2100, minRPM: 1400, maxRPM: 5800, isManual: false),
                FanInfo(id: "F1", name: "F1", currentRPM: 2400, targetRPM: 2400, minRPM: 1500, maxRPM: 6200, isManual: false),
                FanInfo(id: "F2", name: "F2", currentRPM: 2000, targetRPM: 2000, minRPM: 1400, maxRPM: 5600, isManual: false)
            ]
        case .unknown:
            return [
                FanInfo(id: "F0", name: "F0", currentRPM: 2000, targetRPM: 2000, minRPM: 1200, maxRPM: 6000, isManual: false)
            ]
        }
    }

    func discoverFans() -> [FanInfo] {
        fans.map { fan in
            var copy = fan
            copy.name = Self.previewName(id: fan.id, architecture: architecture)
            return copy
        }
    }

    func readThermals() -> ThermalReading {
        ThermalReading(cpuCelsius: 45, gpuCelsius: 44, enclosureCelsius: 38)
    }
}
