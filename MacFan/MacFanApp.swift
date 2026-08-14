import AppKit
import SwiftUI

@main
enum MacFanMain {
    static func main() {
        if CommandLine.arguments.dropFirst().contains("--smc-helper") {
            SMCHelperServer.run()
            return
        }
        MacFanApp.main()
    }
}

struct MacFanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel = FanDashboardViewModel()
    @State private var l10n = LocalizationStore.shared
    @State private var updater = UpdateChecker()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .environment(l10n)
                .environment(updater)
                .frame(minWidth: 980, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 720)
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
            }
        }

        MenuBarExtra {
            MenuBarFanView()
                .environment(viewModel)
                .environment(l10n)
                .environment(updater)
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
        // Prefer asset-catalog template; draw large enough for Retina menu bar.
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        // Prefer asset-catalog AppIcon; fall back to bundled .icns.
        if let named = NSImage(named: NSImage.Name("AppIcon")) {
            NSApp.applicationIconImage = named
        } else if let icns = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let image = NSImage(contentsOf: icns) {
            image.size = NSSize(width: 128, height: 128)
            NSApp.applicationIconImage = image
        }
        NSApp.dockTile.display()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        try? SMCHelperClient.send("QUIT")
    }
}
