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
    private static let daemonPath = "/tmp/macfan-daemon.py"
    private static let installedHelperPath = "/Library/PrivilegedHelperTools/com.macfan.smc"

    /// Shows the system password dialog and installs/starts the root SMC helper.
    static func startHelper() throws {
        if SMCHelperClient.isReady { return }

        guard let exeURL = Bundle.main.executableURL else {
            throw SMCHelperError.missingExecutable
        }
        let exe = exeURL.resolvingSymlinksInPath().path

        try? SMCHelperClient.send("QUIT")
        usleep(200_000)

        try writeDaemonScript()
        try writeInstallScript(sourceExe: exe)

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

        for _ in 0..<100 {
            if SMCHelperClient.isReady { return }
            usleep(120_000)
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        throw SMCHelperError.elevationFailed(
            L10n.t("admin.helperNotReady") + " (v\(version))\n" + helperLogTail()
        )
    }

    /// Install script also pkill's stale helpers and legacy launchd jobs.
    private static func writeDaemonScript() throws {
        let script = """
        #!/usr/bin/env python3
        import os, sys

        exe, log_path = sys.argv[1], sys.argv[2]

        pid = os.fork()
        if pid < 0:
            sys.exit(1)
        if pid > 0:
            sys.exit(0)

        os.setsid()
        pid2 = os.fork()
        if pid2 < 0:
            os._exit(1)
        if pid2 > 0:
            os._exit(0)

        os.chdir("/")
        os.umask(0o022)
        with open(log_path, "a", buffering=1) as log:
            os.dup2(log.fileno(), 1)
            os.dup2(log.fileno(), 2)
            os.execv(exe, [exe, "--smc-helper"])
        """
        try script.write(toFile: daemonPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: daemonPath)
    }

    /// Copy signed helper to /Library, then daemonize — never use nohup inside `do shell script`.
    private static func writeInstallScript(sourceExe: String) throws {
        let log = SMCHelperServer.logPath
        let socket = SMCHelperServer.socketPath
        let script = """
        #!/bin/sh
        SRC='\(shellQuote(sourceExe))'
        HELPER='\(installedHelperPath)'
        LOG='\(log)'
        SOCKET='\(socket)'

        log() { printf '[installer] %s\\n' "$1" >>"$LOG"; }

        rm -f "$LOG" '\(SMCHelperServer.pidPath)'
        : >"$LOG"
        rm -f "$SOCKET"

        if [ ! -f "$SRC" ]; then
          log "source not found: $SRC"
          exit 1
        fi

        mkdir -p /Library/PrivilegedHelperTools
        cp -f "$SRC" "$HELPER" || { log "copy failed"; exit 1; }
        chmod 755 "$HELPER"
        chown root:wheel "$HELPER"
        xattr -cr "$HELPER" 2>/dev/null || true
        if ! /usr/bin/codesign -f -s - --options runtime "$HELPER" >>"$LOG" 2>&1; then
          log "codesign failed"
          exit 1
        fi
        log "installed $HELPER"

        launchctl bootout system/com.macfan.smchelper 2>/dev/null || launchctl unload /Library/LaunchDaemons/com.macfan.smchelper.plist 2>/dev/null || true
        pkill -f 'com.macfan.smc.*--smc-helper' 2>/dev/null || true
        pkill -f 'MacFan.*--smc-helper' 2>/dev/null || true
        sleep 0.15

        if ! /usr/bin/python3 '\(daemonPath)' "$HELPER" "$LOG"; then
          log "daemon bootstrap failed"
          exit 1
        fi
        log "daemon started"

        i=0
        while [ "$i" -lt 100 ]; do
          if [ -S "$SOCKET" ]; then
            chmod 666 "$SOCKET" "$LOG" 2>/dev/null || true
            log "socket ready"
            echo OK
            exit 0
          fi
          sleep 0.12
          i=$((i + 1))
        done

        log "timeout; log tail:"
        tail -8 "$LOG" 2>/dev/null | while IFS= read -r line; do log "  $line"; done
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
            return L10n.t("admin.noLog")
        }
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.lowercased().contains("nohup") }

        if lines.isEmpty, text.lowercased().contains("nohup") {
            return L10n.t("admin.staleLog")
        }
        if lines.isEmpty {
            return L10n.t("admin.noLog")
        }
        return lines.suffix(10).joined(separator: "\n")
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
