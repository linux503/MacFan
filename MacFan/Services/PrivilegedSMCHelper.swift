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
    private static let launcherPath = "/tmp/macfan-install-helper.sh"
    private static let stagingPlistPath = "/tmp/com.macfan.smchelper.plist"
    private static let installedHelperPath = "/Library/PrivilegedHelperTools/com.macfan.smc"
    private static let launchdPlistPath = "/Library/LaunchDaemons/com.macfan.smchelper.plist"
    private static let launchdLabel = "com.macfan.smchelper"

    private static let launchdPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.macfan.smchelper</string>
        <key>ProgramArguments</key>
        <array>
            <string>/Library/PrivilegedHelperTools/com.macfan.smc</string>
            <string>--smc-helper</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>StandardOutPath</key>
        <string>/tmp/macfan-helper.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/macfan-helper.log</string>
    </dict>
    </plist>
    """

    /// Shows the system password dialog and installs/starts the root SMC helper via launchd.
    static func startHelper() throws {
        if SMCHelperClient.isReady { return }

        guard let exe = Bundle.main.executableURL?.path else {
            throw SMCHelperError.missingExecutable
        }

        try? SMCHelperClient.send("QUIT")
        usleep(200_000)

        try writeInstallScript(sourceExe: exe)
        try launchdPlist.write(toFile: stagingPlistPath, atomically: true, encoding: .utf8)

        let escapedLauncher = launcherPath.replacingOccurrences(of: "'", with: "'\\''")
        let appleScript = "do shell script \"'\(escapedLauncher)'\" with administrator privileges"

        var error: NSDictionary?
        guard let script = NSAppleScript(source: appleScript) else {
            throw SMCHelperError.elevationFailed(L10n.t("admin.failed"))
        }
        let result = script.executeAndReturnError(&error)

        if let error {
            let msg = error[NSAppleScript.errorMessage] as? String ?? ""
            if msg.lowercased().contains("user canceled") || msg.contains("-128") {
                throw SMCHelperError.elevationFailed(L10n.t("admin.canceled"))
            }
            throw SMCHelperError.elevationFailed(msg.isEmpty ? L10n.t("admin.failed") : msg)
        }

        let output = result.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if output == "OK", SMCHelperClient.isReady { return }

        for _ in 0..<80 {
            if SMCHelperClient.isReady { return }
            usleep(150_000)
        }

        let logTail = helperLogTail()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        throw SMCHelperError.elevationFailed(
            L10n.t("admin.helperNotReady") + " (v\(version))" + (logTail.isEmpty ? "" : "\n\(logTail)")
        )
    }

    /// Copy helper into /Library and register a LaunchDaemon — avoids quarantine/translocation exec failures.
    private static func writeInstallScript(sourceExe: String) throws {
        let log = SMCHelperServer.logPath
        let socket = SMCHelperServer.socketPath
        let script = """
        #!/bin/sh
        SRC='\(shellQuote(sourceExe))'
        HELPER='\(installedHelperPath)'
        PLIST='\(launchdPlistPath)'
        LABEL='\(launchdLabel)'
        LOG='\(log)'
        SOCKET='\(socket)'

        log() { printf '[installer] %s\\n' "$1" >>"$LOG"; }

        : >"$LOG"
        rm -f "$SOCKET" '\(SMCHelperServer.pidPath)'

        if [ ! -x "$SRC" ]; then
          log "source missing or not executable: $SRC"
          exit 1
        fi

        mkdir -p /Library/PrivilegedHelperTools
        cp -f "$SRC" "$HELPER" || { log "copy failed"; exit 1; }
        chmod 755 "$HELPER"
        chown root:wheel "$HELPER"
        xattr -cr "$HELPER" 2>/dev/null || true
        log "installed helper to $HELPER"

        cp -f '\(stagingPlistPath)' "$PLIST" || { log "plist copy failed"; exit 1; }
        chmod 644 "$PLIST"
        chown root:wheel "$PLIST"
        log "wrote launchd plist"

        launchctl bootout "system/$LABEL" 2>/dev/null || launchctl unload "$PLIST" 2>/dev/null || true
        sleep 0.2
        if ! launchctl bootstrap system "$PLIST" 2>/dev/null; then
          launchctl load -w "$PLIST" 2>/dev/null || { log "launchctl load failed"; exit 1; }
        fi
        log "launchd bootstrap ok"

        i=0
        while [ "$i" -lt 80 ]; do
          if [ -S "$SOCKET" ]; then
            chmod 666 "$SOCKET" 2>/dev/null || true
            chmod 666 "$LOG" 2>/dev/null || true
            log "helper socket ready"
            echo OK
            exit 0
          fi
          sleep 0.15
          i=$((i + 1))
        done

        log "timeout waiting for socket"
        tail -5 "$LOG" 2>/dev/null | while IFS= read -r line; do log "log: $line"; done
        exit 1
        """
        try script.write(toFile: launcherPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: launcherPath)
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func helperLogTail() -> String {
        guard let text = try? String(contentsOfFile: SMCHelperServer.logPath, encoding: .utf8) else {
            return ""
        }
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.contains("nohup:") }
        return lines.suffix(8).joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
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
