import SwiftUI

struct MenuBarFanView: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n
    @Environment(UpdateChecker.self) private var updater

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MacFan")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MFTheme.sand)
                Spacer()
                Text(String(format: "%.0f°", viewModel.thermal.peakCelsius))
                    .font(MFTheme.mono(13, weight: .semibold))
                    .foregroundStyle(MFTheme.accent)
            }

            ForEach(viewModel.fans.prefix(3)) { fan in
                HStack {
                    Text(fan.name)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(MFTheme.mist)
                    Spacer()
                    Text("\(Int(fan.currentRPM)) RPM")
                        .font(MFTheme.mono(11))
                        .foregroundStyle(MFTheme.sand.opacity(0.82))
                }
            }

            Divider().overlay(MFTheme.lineStrong)

            VStack(spacing: 2) {
                MenuActionRow(
                    title: l10n.t("menubar.max"),
                    symbol: "bolt.fill",
                    selected: viewModel.mode == .maximum
                ) {
                    Task { await viewModel.selectMode(.maximum) }
                }
                MenuActionRow(
                    title: l10n.t("menubar.auto"),
                    symbol: "gearshape.2",
                    selected: viewModel.mode == .automatic
                ) {
                    Task { await viewModel.selectMode(.automatic) }
                }
                MenuActionRow(
                    title: l10n.t("menubar.silent"),
                    symbol: "building.2",
                    selected: viewModel.mode == .scene && viewModel.activeScene?.kind == .silentOffice
                ) {
                    if let scene = viewModel.scenes.first(where: { $0.kind == .silentOffice }) {
                        Task { await viewModel.selectScene(scene) }
                    }
                }
            }

            Divider().overlay(MFTheme.lineStrong)

            VStack(spacing: 2) {
                MenuActionRow(title: l10n.t("update.check"), symbol: "arrow.triangle.2.circlepath", selected: false) {
                    Task { await updater.checkForUpdates(l10n: l10n) }
                }
                MenuActionRow(title: l10n.t("website"), symbol: "globe", selected: false) {
                    updater.openWebsite()
                }
            }

            Divider().overlay(MFTheme.lineStrong)
            Text(viewModel.statusMessage)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(MFTheme.mistDim)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 260)
        .background(MFTheme.inkLift)
        .id("\(l10n.language.rawValue)")
        .onAppear {
            if viewModel.fans.isEmpty {
                viewModel.start()
            }
        }
    }
}

private struct MenuActionRow: View {
    let title: String
    let symbol: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selected ? MFTheme.ink : MFTheme.mist)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(selected ? MFTheme.accent : MFTheme.surface)
                    )
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(MFTheme.sand)
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(MFTheme.accent)
                }
            }
        }
        .buttonStyle(MFMenuButtonStyle(selected: selected, compact: true))
    }
}
