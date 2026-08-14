import Foundation

/// Swift facade over the C AppleSMC bridge (`smc.c`).
final class SMCClient: @unchecked Sendable {
    static let shared = SMCClient()

    private var connection: io_connect_t = 0
    private let lock = NSLock()

    var isConnected: Bool {
        lock.lock(); defer { lock.unlock() }
        return connection != 0
    }

    @discardableResult
    func open() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if connection != 0 { return true }
        var conn: io_connect_t = 0
        guard MacFanSMCOpen(&conn) == KERN_SUCCESS else { return false }
        connection = conn
        return true
    }

    func close() {
        lock.lock(); defer { lock.unlock() }
        if connection != 0 {
            MacFanSMCClose(connection)
            connection = 0
        }
    }

    func fanCount() -> Int {
        guard open() else { return 0 }
        lock.lock(); defer { lock.unlock() }
        return Int(MacFanSMCFanCount(connection))
    }

    func readFans() throws -> [FanInfo] {
        guard open() else { throw FanControlError.smcUnavailable("无法打开 AppleSMC") }
        lock.lock()
        let count = Int(MacFanSMCFanCount(connection))
        lock.unlock()
        guard count > 0 else { return [] }

        var fans: [FanInfo] = []
        for index in 0..<count {
            lock.lock()
            let current = Double(MacFanSMCFanSpeed(connection, Int32(index)))
            let minRPM = Double(MacFanSMCFanMin(connection, Int32(index)))
            let maxRPM = Double(MacFanSMCFanMax(connection, Int32(index)))
            let target = Double(MacFanSMCFanTarget(connection, Int32(index)))
            var nameBuf = [CChar](repeating: 0, count: 64)
            let nameOK = MacFanSMCReadFanName(connection, Int32(index), &nameBuf, 64) == 0
            lock.unlock()

            let name: String
            if nameOK {
                let parsed = String(cString: nameBuf).trimmingCharacters(in: .whitespacesAndNewlines)
                name = parsed.isEmpty ? "风扇 \(index)" : parsed
            } else {
                name = "风扇 \(index)"
            }
            fans.append(
                FanInfo(
                    id: "F\(index)",
                    name: name,
                    currentRPM: max(0, current),
                    targetRPM: max(0, target),
                    minRPM: minRPM > 0 ? minRPM : 1200,
                    maxRPM: maxRPM > 0 ? maxRPM : 6000,
                    isManual: false
                )
            )
        }
        return fans
    }

    func readThermals() -> ThermalReading? {
        guard open() else { return nil }
        let cpuKeys = ["Tc0a", "TC0P", "Tp01", "Tp05", "Ts0P"]
        let gpuKeys = ["Tg0a", "TG0P", "Tg0f", "Tg05"]
        let enclosureKeys = ["Ts0P", "TB0T", "TW0P"]

        func firstTemp(_ keys: [String]) -> Double? {
            for key in keys {
                lock.lock()
                let value = MacFanSMCReadTemp(connection, key)
                lock.unlock()
                if value > 1 && value < 150 { return Double(value) }
            }
            return nil
        }

        guard let cpu = firstTemp(cpuKeys) else { return nil }
        let gpu = firstTemp(gpuKeys) ?? cpu
        let enclosure = firstTemp(enclosureKeys) ?? (cpu - 6)
        return ThermalReading(cpuCelsius: cpu, gpuCelsius: gpu, enclosureCelsius: enclosure)
    }

    func setManual(fanIndex: Int, rpm: Double) throws {
        guard geteuid() == 0 else { throw FanControlError.privilegeRequired }
        guard open() else { throw FanControlError.smcUnavailable("无法打开 AppleSMC") }
        lock.lock()
        let result = MacFanSMCSetFanRPM(connection, Int32(fanIndex), Int32(rpm.rounded()))
        lock.unlock()
        if result == kern_return_t(bitPattern: 0xe00002c1) { throw FanControlError.privilegeRequired }
        guard result == KERN_SUCCESS else {
            throw FanControlError.smcUnavailable("设定风扇失败 (\(String(format: "%08x", UInt32(bitPattern: Int32(result)))))")
        }
    }

    func setMaximum(fanIndex: Int) throws {
        guard open() else { throw FanControlError.smcUnavailable("无法打开 AppleSMC") }
        lock.lock()
        let maxRPM = MacFanSMCFanMax(connection, Int32(fanIndex))
        lock.unlock()
        try setManual(fanIndex: fanIndex, rpm: Double(maxRPM))
    }

    func setAutomatic(fanIndex: Int) throws {
        guard geteuid() == 0 else { throw FanControlError.privilegeRequired }
        guard open() else { throw FanControlError.smcUnavailable("无法打开 AppleSMC") }
        lock.lock()
        let result = MacFanSMCSetFanAuto(connection, Int32(fanIndex))
        lock.unlock()
        if result == kern_return_t(bitPattern: 0xe00002c1) { throw FanControlError.privilegeRequired }
        guard result == KERN_SUCCESS else {
            throw FanControlError.smcUnavailable("恢复自动失败 (\(String(format: "%08x", UInt32(bitPattern: Int32(result)))))")
        }
    }

    func fanIndex(from id: String) -> Int? {
        if id.hasPrefix("F"), let n = Int(id.dropFirst()) { return n }
        return Int(id)
    }
}
