import SwiftUI

/// Prominent admin authorization card for the main dashboard.
struct AdminAuthorizationCard: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(MFTheme.amber.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(MFTheme.amber)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n.t("admin.title"))
                        .font(MFTheme.displayFont(20))
                        .foregroundStyle(MFTheme.sand)
                    Text(l10n.t("admin.body"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(MFTheme.mist)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    viewModel.relaunchAsAdministrator()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isBusy {
                            ProgressView()
                                .controlSize(.small)
                                .tint(MFTheme.ink)
                        } else {
                            Image(systemName: "key.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text(viewModel.isBusy ? l10n.t("admin.authorizing") : l10n.t("admin.button"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
                .foregroundStyle(MFTheme.ink)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(hovering && !viewModel.isBusy ? MFTheme.accent.opacity(0.92) : MFTheme.accent)
                )
                .disabled(viewModel.isBusy)
                .onHover { hovering = $0 }
            }

            if let hint = activeHint {
                Text(hint)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MFTheme.mistDim)
                    .padding(.top, 14)
            }

            Text(appVersionLine)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(MFTheme.mistDim.opacity(0.85))
                .padding(.top, 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MFTheme.amber.opacity(0.10), MFTheme.surface.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MFTheme.amber.opacity(0.28), lineWidth: 1)
        )
    }

    private var activeHint: String? {
        if viewModel.isBusy { return l10n.t("admin.passwordHint") }
        if let error = viewModel.lastError, viewModel.needsAdminToControl { return error }
        return l10n.t("admin.passwordHint")
    }

    private var appVersionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return "MacFan v\(version)"
    }
}
