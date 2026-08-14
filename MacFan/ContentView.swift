import SwiftUI

struct ContentView: View {
    @Environment(FanDashboardViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            AtmosphereBackground()
            HStack(spacing: 0) {
                SidebarPanel()
                    .frame(width: 272)
                Rectangle()
                    .fill(MFTheme.line)
                    .frame(width: 1)
                MainDashboard()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
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
                    Color(red: 0.07, green: 0.08, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Very soft cool wash — almost invisible
            RadialGradient(
                colors: [MFTheme.accent.opacity(0.05), .clear],
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
        .frame(width: 1120, height: 740)
}
