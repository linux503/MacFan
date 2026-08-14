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
            return "当前机型暂不支持直接写入风扇转速。"
        case .privilegeRequired:
            return "需要管理员权限才能修改真实风扇转速。请点击「以管理员身份启动」。"
        case .fanNotFound(let id):
            return "未找到风扇：\(id)"
        case .smcUnavailable(let detail):
            return "SMC 不可用：\(detail)"
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
        self.isPrivileged = geteuid() == 0
    }

    func refreshPrivilege() {
        isPrivileged = geteuid() == 0
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
        let fans = try smc.readFans()
        for index in fans.indices {
            try smc.setAutomatic(fanIndex: index)
        }
    }

    func setMaximum() async throws {
        try await ensureLiveWritable()
        let fans = try smc.readFans()
        for index in fans.indices {
            try smc.setMaximum(fanIndex: index)
        }
    }

    func setManual(fanID: String, rpm: Double) async throws {
        try await ensureLiveWritable()
        guard let index = smc.fanIndex(from: fanID) else {
            throw FanControlError.fanNotFound(fanID)
        }
        try smc.setManual(fanIndex: index, rpm: rpm)
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
            throw FanControlError.smcUnavailable("未读到本机风扇，无法实控")
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
        switch architecture {
        case .appleSilicon:
            self.fans = [
                FanInfo(id: "F0", name: "左排气风扇", currentRPM: 0, targetRPM: 0, minRPM: 1200, maxRPM: 6150, isManual: false),
                FanInfo(id: "F1", name: "右排气风扇", currentRPM: 0, targetRPM: 0, minRPM: 1200, maxRPM: 6150, isManual: false)
            ]
        case .intel:
            self.fans = [
                FanInfo(id: "F0", name: "进气风扇", currentRPM: 2100, targetRPM: 2100, minRPM: 1400, maxRPM: 5800, isManual: false),
                FanInfo(id: "F1", name: "CPU 风扇", currentRPM: 2400, targetRPM: 2400, minRPM: 1500, maxRPM: 6200, isManual: false),
                FanInfo(id: "F2", name: "排气风扇", currentRPM: 2000, targetRPM: 2000, minRPM: 1400, maxRPM: 5600, isManual: false)
            ]
        case .unknown:
            self.fans = [
                FanInfo(id: "F0", name: "系统风扇", currentRPM: 2000, targetRPM: 2000, minRPM: 1200, maxRPM: 6000, isManual: false)
            ]
        }
    }

    func discoverFans() -> [FanInfo] { fans }

    func readThermals() -> ThermalReading {
        ThermalReading(cpuCelsius: 45, gpuCelsius: 44, enclosureCelsius: 38)
    }
}
