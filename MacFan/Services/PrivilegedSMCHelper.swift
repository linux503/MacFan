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
    static let logPath = "/tmp/macfan-helper.log"
    static let pidPath = "/tmp/macfan-helper.pid"

    static func run() {
        unlink(socketPath)
        writePID()

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            log("socket() failed")
            exit(1)
        }

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
        guard bindOK else {
            log("bind() failed")
            exit(2)
        }
        _ = chmod(socketPath, 0o666)
        guard listen(fd, 8) == 0 else {
            log("listen() failed")
            exit(3)
        }

        log("helper ready on \(socketPath)")
        _ = chmod(logPath, 0o666)

        let smc = SMCClient.shared
        _ = smc.open()

        while true {
            let client = accept(fd, nil, nil)
            if client < 0 { continue }
            let shouldQuit = handle(client: client, smc: smc)
            close(client)
            if shouldQuit {
                unlink(socketPath)
                unlink(pidPath)
                exit(0)
            }
        }
    }

    private static func writePID() {
        let pid = String(getpid())
        try? pid.write(toFile: pidPath, atomically: true, encoding: .utf8)
    }

    private static func log(_ message: String) {
        let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
        if let data = line.data(using: .utf8),
           let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? line.write(toFile: logPath, atomically: false, encoding: .utf8)
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
    /// Shows the system password dialog and installs a root LaunchDaemon helper.
    static func startHelper() async throws {
        if SMCHelperClient.isReady { return }

        guard let exeURL = Bundle.main.executableURL else {
            throw SMCHelperError.missingExecutable
        }
        let exe = exeURL.resolvingSymlinksInPath().path

        guard let installer = Bundle.main.url(forResource: "install-smc-helper", withExtension: "sh") else {
            throw SMCHelperError.elevationFailed(L10n.t("admin.missingInstaller"))
        }

        try? SMCHelperClient.send("QUIT")
        try await Task.sleep(nanoseconds: 200_000_000)

        try runInstaller(script: installer.path, executable: exe)

        if SMCHelperClient.isReady { return }
        for _ in 0..<50 {
            if SMCHelperClient.isReady { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        throw SMCHelperError.elevationFailed(failureMessage(executable: exe))
    }

    private static func runInstaller(script: String, executable: String) throws {
        let cmd = "/bin/sh \(shellQuote(script)) \(shellQuote(executable))"
        let prompt = L10n.t("admin.osascriptPrompt")
        let source = """
        do shell script \(appleString(cmd)) with administrator privileges with prompt \(appleString(prompt))
        """

        var error: NSDictionary?
        let result: NSAppleEventDescriptor
        if Thread.isMainThread {
            result = executeAppleScript(source, error: &error)
        } else {
            var boxed: NSAppleEventDescriptor?
            var boxedError: NSDictionary?
            DispatchQueue.main.sync {
                boxed = executeAppleScript(source, error: &boxedError)
            }
            error = boxedError
            result = boxed ?? NSAppleEventDescriptor()
        }

        if let error {
            let msg = error[NSAppleScript.errorMessage] as? String ?? ""
            if msg.lowercased().contains("user canceled") || msg.contains("-128") {
                throw SMCHelperError.elevationFailed(L10n.t("admin.canceled"))
            }
            throw SMCHelperError.elevationFailed(msg.isEmpty ? L10n.t("admin.failed") : msg)
        }

        let output = result.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if output.contains("OK") { return }
        if !output.isEmpty {
            throw SMCHelperError.elevationFailed(output + "\n" + failureMessage(executable: executable))
        }
    }

    private static func executeAppleScript(_ source: String, error: inout NSDictionary?) -> NSAppleEventDescriptor {
        guard let script = NSAppleScript(source: source) else {
            error = [NSAppleScript.errorMessage: L10n.t("admin.failed")] as NSDictionary
            return NSAppleEventDescriptor()
        }
        return script.executeAndReturnError(&error)
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleString(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    private static func failureMessage(executable: String) -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        var parts = [
            L10n.t("admin.helperNotReady") + " (v\(version))",
            executable
        ]
        if executable.contains("/DerivedData/") || executable.contains("/Build/Products/Debug/") {
            parts.append(L10n.t("admin.debugBuild"))
        }
        parts.append(helperLogTail())
        return parts.joined(separator: "\n")
    }

    private static func helperLogTail() -> String {
        guard let text = try? String(contentsOfFile: SMCHelperServer.logPath, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return L10n.t("admin.noLog")
        }
        if !text.contains("[installer]") && text.lowercased().contains("nohup") {
            return L10n.t("admin.staleLog")
        }
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.lowercased().contains("nohup") }
        if lines.isEmpty { return L10n.t("admin.staleLog") }
        return lines.suffix(12).joined(separator: "\n")
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
