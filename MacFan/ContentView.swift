import SwiftUI

struct ContentView: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n
    @Environment(UpdateChecker.self) private var updater
    @Environment(ThemeStore.self) private var theme

    var body: some View {
        ZStack {
            AtmosphereBackground()
            HStack(spacing: 0) {
                SidebarPanel()
                    .frame(width: 256)
                Rectangle()
                    .fill(MFTheme.line)
                    .frame(width: 1)
                MainDashboard()
            }
        }
        .preferredColorScheme(theme.appearance.colorScheme)
        .id("\(l10n.language.rawValue)-\(theme.appearance.rawValue)")
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .alert(updater.alertTitle, isPresented: Binding(
            get: { updater.alertPresented },
            set: { updater.alertPresented = $0 }
        )) {
            if case .available = updater.lastResult {
                Button(l10n.t("update.openRelease")) { updater.openReleaseOrWebsite() }
                Button(l10n.t("update.openSite")) { updater.openWebsite() }
                Button(l10n.t("update.later"), role: .cancel) {}
            } else if case .failed = updater.lastResult {
                Button(l10n.t("update.openSite")) { updater.openWebsite() }
                Button(l10n.t("update.later"), role: .cancel) {}
            } else {
                Button(l10n.t("update.openSite")) { updater.openWebsite() }
                Button(l10n.t("ok"), role: .cancel) {}
            }
        } message: {
            Text(updater.alertMessage)
        }
    }
}

private struct AtmosphereBackground: View {
    @Environment(ThemeStore.self) private var theme

    var body: some View {
        ZStack {
            MFTheme.ink
            LinearGradient(
                colors: [
                    MFTheme.inkLift,
                    MFTheme.ink,
                    MFTheme.atmosphereBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [MFTheme.accent.opacity(theme.appearance == .light ? 0.12 : 0.10), .clear],
                center: UnitPoint(x: 0.88, y: 0.10),
                startRadius: 16,
                endRadius: 540
            )
            RadialGradient(
                colors: [MFTheme.amber.opacity(theme.appearance == .light ? 0.06 : 0.05), .clear],
                center: UnitPoint(x: 0.08, y: 0.92),
                startRadius: 10,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .environment(FanDashboardViewModel())
        .environment(LocalizationStore.shared)
        .environment(ThemeStore.shared)
        .environment(UpdateChecker())
        .frame(width: 1120, height: 740)
}
