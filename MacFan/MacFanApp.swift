import AppKit
import SwiftUI

@main
enum MacFanMain {
    static let revealNotification = Notification.Name("com.macfan.app.revealMainWindow")
    static let openWindowNotification = Notification.Name("com.macfan.app.openMainWindow")

    static func main() {
        if CommandLine.arguments.dropFirst().contains("--smc-helper") {
            SMCHelperServer.run()
            return
        }
        if activateExistingInstance() {
            return
        }
        MacFanApp.main()
    }

    /// One GUI only. The SMC helper is a different binary path and is ignored.
    private static func activateExistingInstance() -> Bool {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.macfan.app"
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).filter { app in
            guard app.processIdentifier != me, !app.isTerminated else { return false }
            if let path = app.executableURL?.path, path.contains("PrivilegedHelperTools") {
                return false
            }
            return app.activationPolicy != .prohibited
        }
        guard let existing = others.first else { return false }
        DistributedNotificationCenter.default().postNotificationName(
            revealNotification,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        existing.activate()
        return true
    }
}

struct MacFanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = FanDashboardViewModel()
    @State private var l10n = LocalizationStore.shared
    @State private var theme = ThemeStore.shared
    @State private var updater = UpdateChecker()

    var body: some Scene {
        Window("MacFan", id: "main") {
            ContentView()
                .environment(viewModel)
                .environment(l10n)
                .environment(theme)
                .environment(updater)
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 720)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button(l10n.t("update.check")) {
                    Task { await updater.checkForUpdates(l10n: l10n) }
                }
                .keyboardShortcut("u", modifiers: [.command])

                Button(l10n.t("website")) {
                    updater.openWebsite()
                }
                .keyboardShortcut("0", modifiers: [.command])

                Divider()

                Button(l10n.t("language.zh")) {
                    l10n.language = .zhHans
                    viewModel.refreshLocalizedStatus()
                }
                Button(l10n.t("language.en")) {
                    l10n.language = .english
                    viewModel.refreshLocalizedStatus()
                }

                Divider()

                Button(l10n.t("appearance.dark")) {
                    theme.appearance = .dark
                }
                Button(l10n.t("appearance.light")) {
                    theme.appearance = .light
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarFanView()
                .environment(viewModel)
                .environment(l10n)
                .environment(theme)
                .environment(updater)
                .background(MainWindowReopener())
        } label: {
            Group {
                if let img = menuBarImage {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: "fan")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 22, height: 22)
            .help("MacFan")
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarImage: NSImage? {
        let pointSize = NSSize(width: 22, height: 22)
        if let img = NSImage(named: "MenuBarIcon") {
            let copy = img.copy() as? NSImage ?? img
            copy.isTemplate = true
            copy.size = pointSize
            return copy
        }
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            img.size = pointSize
            return img
        }
        return nil
    }
}

/// Lives in the menu bar extra so `openWindow` still works after the main window is closed.
private struct MainWindowReopener: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: MacFanMain.openWindowNotification)) { _ in
                openWindow(id: "main")
            }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(revealMainWindow),
            name: MacFanMain.revealNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        revealMainWindow()
        return true
    }

    @objc func revealMainWindow(_ notification: Notification? = nil) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: Self.isMainWindow) {
            if window.isMiniaturized { window.deminiaturize(nil) }
            window.makeKeyAndOrderFront(nil)
            return
        }
        NotificationCenter.default.post(name: MacFanMain.openWindowNotification, object: nil)
    }

    private static func isMainWindow(_ window: NSWindow) -> Bool {
        if window.level != .normal { return false }
        if window.frame.width < 500 { return false }
        let name = String(describing: type(of: window))
        if name.localizedCaseInsensitiveContains("StatusBar") { return false }
        if name.localizedCaseInsensitiveContains("MenuBar") { return false }
        return true
    }
}
