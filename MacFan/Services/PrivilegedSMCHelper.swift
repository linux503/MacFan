import AppKit
import Darwin
import Foundation

enum SMCHelperError: LocalizedError {
    case missingExecutable
    case elevationFailed(String)
    case helperNotReady
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingExecutable:
            return L10n.t("admin.missingExe")
        case .elevationFailed(let detail):
            return detail.isEmpty ? L10n.t("admin.failed") : detail
        case .helperNotReady:
            return L10n.t("admin.helperNotReady")
        case .commandFailed(let detail):
            return detail
        }
    }
}

/// Root-side Unix-socket helper: GUI stays as the logged-in user; SMC writes go through this process.
enum SMCHelperServer {
    static let socketPath = "/tmp/macfan-smc.sock"

    static func run() {
        unlink(socketPath)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { exit(1) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path.0) { dst in
            pathBytes.withUnsafeBufferPointer { src in
                let count = min(src.count, 104)
                for i in 0..<count {
                    dst.advanced(by: i).pointee = src[i]
                }
            }
        }

        let bindOK: Bool = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0
            }
        }
        guard bindOK else { exit(2) }
        _ = chmod(socketPath, 0o666)
        guard listen(fd, 8) == 0 else { exit(3) }

        let smc = SMCClient.shared
        _ = smc.open()

        while true {
            let client = accept(fd, nil, nil)
            if client < 0 { continue }
            let shouldQuit = handle(client: client, smc: smc)
            close(client)
            if shouldQuit {
                unlink(socketPath)
                exit(0)
            }
        }
    }

    private static func handle(client: Int32, smc: SMCClient) -> Bool {
        guard let line = readLine(from: client) else { return false }
        let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let cmd = parts.first?.uppercased() else {
            writeLine(to: client, "ERR empty")
            return false
        }

        do {
            switch cmd {
            case "PING":
                writeLine(to: client, "OK")
            case "AUTO":
                let fans = try smc.readFans()
                for index in fans.indices {
                    try smc.setAutomatic(fanIndex: index)
                }
                writeLine(to: client, "OK")
            case "MAX":
                let fans = try smc.readFans()
                for index in fans.indices {
                    try smc.setMaximum(fanIndex: index)
                }
                writeLine(to: client, "OK")
            case "SET":
                guard parts.count >= 3, let index = Int(parts[1]), let rpm = Double(parts[2]) else {
                    writeLine(to: client, "ERR bad SET")
                    return false
                }
                try smc.setManual(fanIndex: index, rpm: rpm)
                writeLine(to: client, "OK")
            case "QUIT":
                writeLine(to: client, "OK")
                return true
            default:
                writeLine(to: client, "ERR unknown")
            }
        } catch {
            writeLine(to: client, "ERR \(error.localizedDescription)")
        }
        return false
    }
}

enum SMCHelperClient {
    static var isReady: Bool {
        (try? send("PING")) == "OK"
    }

    @discardableResult
    static func send(_ command: String) throws -> String {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw SMCHelperError.helperNotReady }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = SMCHelperServer.socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path.0) { dst in
            pathBytes.withUnsafeBufferPointer { src in
                let count = min(src.count, 104)
                for i in 0..<count {
                    dst.advanced(by: i).pointee = src[i]
                }
            }
        }

        let connected: Bool = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                Darwin.connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size)) == 0
            }
        }
        defer { close(fd) }
        guard connected else { throw SMCHelperError.helperNotReady }

        writeLine(to: fd, command)
        guard let reply = readLine(from: fd) else { throw SMCHelperError.helperNotReady }
        if reply == "OK" { return reply }
        if reply.hasPrefix("ERR ") {
            throw SMCHelperError.commandFailed(String(reply.dropFirst(4)))
        }
        throw SMCHelperError.commandFailed(reply)
    }
}

enum PrivilegedElevator {
    /// Shows the system password dialog and starts the root SMC helper (GUI stays as the current user).
    static func startHelper() throws {
        if SMCHelperClient.isReady { return }

        guard let exe = Bundle.main.executableURL?.path else {
            throw SMCHelperError.missingExecutable
        }

        let log = "/tmp/macfan-helper.log"
        let shell =
            "rm -f /tmp/macfan-smc.sock; " +
            "/bin/rm -f '\(log)'; " +
            "/usr/bin/nohup '\(exe)' --smc-helper >>'\(log)' 2>&1 &"

        let escaped = shell
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e",
            "do shell script \"\(escaped)\" with administrator privileges"
        ]
        let errPipe = Pipe()
        let outPipe = Pipe()
        process.standardError = errPipe
        process.standardOutput = outPipe

        do {
            try process.run()
        } catch {
            throw SMCHelperError.elevationFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errText = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if errText.lowercased().contains("user canceled") || errText.contains("-128") {
                throw SMCHelperError.elevationFailed(L10n.t("admin.canceled"))
            }
            throw SMCHelperError.elevationFailed(errText.isEmpty ? L10n.t("admin.failed") : errText)
        }

        for _ in 0..<40 {
            if SMCHelperClient.isReady { return }
            usleep(100_000)
        }

        let logTail = (try? String(contentsOfFile: log, encoding: .utf8))?.suffix(400) ?? ""
        throw SMCHelperError.elevationFailed(
            L10n.t("admin.helperNotReady") + (logTail.isEmpty ? "" : "\n\(logTail)")
        )
    }
}

private func readLine(from fd: Int32) -> String? {
    var data = Data()
    var byte: UInt8 = 0
    while true {
        let n = read(fd, &byte, 1)
        if n <= 0 { break }
        if byte == UInt8(ascii: "\n") { break }
        data.append(byte)
        if data.count > 4096 { break }
    }
    guard !data.isEmpty, let s = String(data: data, encoding: .utf8) else { return nil }
    return s.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func writeLine(to fd: Int32, _ line: String) {
    let payload = line + "\n"
    payload.withCString { ptr in
        _ = Darwin.write(fd, ptr, strlen(ptr))
    }
}
