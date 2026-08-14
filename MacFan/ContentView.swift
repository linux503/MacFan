import SwiftUI

struct ContentView: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n
    @Environment(UpdateChecker.self) private var updater

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
        .preferredColorScheme(.dark)
        .id(l10n.language)
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
    var body: some View {
        ZStack {
            MFTheme.ink
            LinearGradient(
                colors: [
                    MFTheme.inkLift,
                    MFTheme.ink,
                    Color(red: 0.035, green: 0.050, blue: 0.090)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [MFTheme.accent.opacity(0.08), .clear],
                center: UnitPoint(x: 0.88, y: 0.12),
                startRadius: 20,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .environment(FanDashboardViewModel())
        .environment(LocalizationStore.shared)
        .environment(UpdateChecker())
        .frame(width: 1120, height: 740)
}
