import AppKit
import SwiftUI

struct SidebarPanel: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n
    @Environment(UpdateChecker.self) private var updater

    var body: some View {
        VStack(spacing: 0) {
            BrandHeader()
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

            Rectangle()
                .fill(MFTheme.line)
                .frame(height: 1)
                .padding(.horizontal, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    SidebarSection(title: l10n.t("section.control")) {
                        VStack(spacing: 1) {
                            ForEach(FanControlMode.allCases) { mode in
                                let selected = viewModel.mode == mode
                                Button {
                                    Task { await viewModel.selectMode(mode) }
                                } label: {
                                    ModeRowLabel(mode: mode, selected: selected)
                                }
                                .buttonStyle(MFMenuButtonStyle(selected: selected))
                                .help(mode.subtitle)
                            }
                        }
                    }

                    SidebarSection(title: l10n.t("section.extensions")) {
                        VStack(spacing: 0) {
                            ToggleRow(title: l10n.t("toggle.appLink"), isOn: Binding(
                                get: { viewModel.appLinkEnabled },
                                set: { viewModel.appLinkEnabled = $0 }
                            ), showDivider: true)
                            ToggleRow(title: l10n.t("toggle.schedule"), isOn: Binding(
                                get: { viewModel.scheduleEnabled },
                                set: { viewModel.scheduleEnabled = $0 }
                            ), showDivider: false)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MFTheme.surface.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(MFTheme.line, lineWidth: 1)
                        )
                    }

                    SidebarSection(title: l10n.t("section.more")) {
                        VStack(spacing: 0) {
                            LanguagePicker(showDivider: true)
                            SidebarLinkButton(
                                title: updater.isChecking ? l10n.t("update.checking") : l10n.t("update.check"),
                                symbol: "arrow.triangle.2.circlepath",
                                showDivider: true
                            ) {
                                Task { await updater.checkForUpdates(l10n: l10n) }
                            }
                            .disabled(updater.isChecking)
                            SidebarLinkButton(
                                title: l10n.t("website"),
                                symbol: "globe",
                                showDivider: false
                            ) {
                                updater.openWebsite()
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(MFTheme.surface.opacity(0.7))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(MFTheme.line, lineWidth: 1)
                        )

                        Text(String(format: l10n.t("currentVersion"), updater.currentVersion))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(MFTheme.mistDim)
                            .padding(.top, 8)
                            .padding(.leading, 2)
                    }

                    if viewModel.needsAdminToControl {
                        AdminBanner()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            Rectangle()
                .fill(MFTheme.line)
                .frame(height: 1)
                .padding(.horizontal, 16)

            MachineFooter()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(MFTheme.inkLift.opacity(0.94))
        .id(l10n.language)
    }
}

private struct SidebarSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(MFTheme.mistDim)
                .padding(.leading, 2)
            content
        }
    }
}

private struct BrandHeader: View {
    @Environment(LocalizationStore.self) private var l10n

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let url = Bundle.main.url(forResource: "MacFan-logo", withExtension: "png"),
                   let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    Image(systemName: "fan")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(MFTheme.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(MFTheme.lineStrong, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("MacFan")
                    .font(MFTheme.brandFont(18, weight: .bold))
                    .foregroundStyle(MFTheme.sand)
                Text(l10n.t("brand.tagline"))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(MFTheme.mistDim)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct ModeRowLabel: View {
    let mode: FanControlMode
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: mode.symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? MFTheme.ink : MFTheme.mist)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? MFTheme.accent : MFTheme.surfaceLift.opacity(0.9))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(mode.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MFTheme.sand.opacity(selected ? 1 : 0.86))
                Text(mode.subtitle)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(selected ? MFTheme.accent.opacity(0.88) : MFTheme.mistDim)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MFTheme.accent)
            }
        }
    }
}

private struct LanguagePicker: View {
    var showDivider: Bool = false
    @Environment(LocalizationStore.self) private var l10n
    @Environment(FanDashboardViewModel.self) private var viewModel
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "character.book.closed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MFTheme.mist)
                    .frame(width: 22)
                Text(l10n.t("language"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MFTheme.sand.opacity(0.9))
                Spacer(minLength: 0)
                Picker("", selection: Binding(
                    get: { l10n.language },
                    set: { newValue in
                        l10n.language = newValue
                        viewModel.refreshLocalizedStatus()
                    }
                )) {
                    Text(l10n.t("language.zh")).tag(AppLanguage.zhHans)
                    Text(l10n.t("language.en")).tag(AppLanguage.english)
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(MFTheme.accent)
                .controlSize(.small)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(hovering ? Color.white.opacity(0.04) : Color.clear)
            .onHover { hovering = $0 }

            if showDivider {
                Rectangle()
                    .fill(MFTheme.line)
                    .frame(height: 1)
                    .padding(.leading, 42)
            }
        }
    }
}

private struct SidebarLinkButton: View {
    let title: String
    let symbol: String
    var showDivider: Bool = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MFTheme.mist)
                        .frame(width: 22)
                    Text(title)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(MFTheme.sand.opacity(0.9))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(MFTheme.mistDim)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(hovering ? Color.white.opacity(0.04) : Color.clear)
            .onHover { hovering = $0 }

            if showDivider {
                Rectangle()
                    .fill(MFTheme.line)
                    .frame(height: 1)
                    .padding(.leading, 42)
            }
        }
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var showDivider: Bool = false
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(MFTheme.sand.opacity(0.9))
                Spacer()
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(MFTheme.accent)
                    .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(hovering ? Color.white.opacity(0.04) : Color.clear)
            .onHover { hovering = $0 }

            if showDivider {
                Rectangle()
                    .fill(MFTheme.line)
                    .frame(height: 1)
                    .padding(.leading, 12)
            }
        }
    }
}

private struct AdminBanner: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @Environment(LocalizationStore.self) private var l10n
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(l10n.t("admin.title"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(MFTheme.amber)
            Text(l10n.t("admin.body"))
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(MFTheme.mist)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                viewModel.relaunchAsAdministrator()
            } label: {
                Text(l10n.t("admin.button"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MFTheme.ink)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovering ? MFTheme.accent.opacity(0.88) : MFTheme.accent)
            )
            .onHover { hovering = $0 }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MFTheme.amber.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MFTheme.amber.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct MachineFooter: View {
    @Environment(FanDashboardViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(viewModel.architectureBadge, systemImage: viewModel.machine.architecture.symbolName)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(MFTheme.mistDim)
                .lineLimit(2)
            Text(viewModel.statusMessage)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(MFTheme.accent)
                .lineLimit(2)
            if let error = viewModel.lastError {
                Text(error)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(MFTheme.amber)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(MFTheme.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(MFTheme.line, lineWidth: 1)
        )
    }
}
