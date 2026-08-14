import AppKit
import SwiftUI

struct SidebarPanel: View {
    @Environment(FanDashboardViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            BrandHeader()

            VStack(alignment: .leading, spacing: 10) {
                MFSectionHeader(title: "控制模式")
                VStack(spacing: 2) {
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

            VStack(alignment: .leading, spacing: 10) {
                MFSectionHeader(title: "扩展")
                ToggleRow(title: "应用联动", isOn: Binding(
                    get: { viewModel.appLinkEnabled },
                    set: { viewModel.appLinkEnabled = $0 }
                ))
                ToggleRow(title: "夜间调度", isOn: Binding(
                    get: { viewModel.scheduleEnabled },
                    set: { viewModel.scheduleEnabled = $0 }
                ))
            }

            if viewModel.needsAdminToControl {
                AdminBanner()
            }

            Spacer(minLength: 12)
            MachineFooter()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(MFTheme.inkLift.opacity(0.92))
    }
}

private struct BrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let url = Bundle.main.url(forResource: "MacFan-logo", withExtension: "png"),
                   let image = NSImage(contentsOf: url) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    Image(systemName: "fan")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(MFTheme.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(MFTheme.lineStrong, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("MacFan")
                    .font(MFTheme.brandFont(24, weight: .bold))
                    .foregroundStyle(MFTheme.sand)
                Text("精准风控 · Intel / Apple Silicon")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MFTheme.mistDim)
            }
        }
    }
}

private struct ModeRowLabel: View {
    let mode: FanControlMode
    let selected: Bool

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: mode.symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? MFTheme.ink : MFTheme.mist)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(selected ? MFTheme.accent : MFTheme.surface)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(mode.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MFTheme.sand.opacity(selected ? 1 : 0.82))
                Text(mode.subtitle)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(selected ? MFTheme.accent.opacity(0.9) : MFTheme.mistDim)
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

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    @State private var hovering = false

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(MFTheme.sand.opacity(0.88))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(MFTheme.accent)
                .controlSize(.small)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(hovering ? MFTheme.surfaceLift.opacity(0.7) : MFTheme.surface.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(hovering ? MFTheme.lineStrong : Color.clear, lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.14), value: hovering)
        .onHover { hovering = $0 }
    }
}

private struct AdminBanner: View {
    @Environment(FanDashboardViewModel.self) private var viewModel
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("需要管理员权限")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MFTheme.amber)
            Text("写入 SMC 才能真正调速。输入密码后以管理员身份重启。")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(MFTheme.mist)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                viewModel.relaunchAsAdministrator()
            } label: {
                Text("以管理员身份启动")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MFTheme.ink)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(hovering ? MFTheme.accent.opacity(0.88) : MFTheme.accent)
            )
            .onHover { hovering = $0 }
        }
        .padding(12)
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
        VStack(alignment: .leading, spacing: 7) {
            Label(viewModel.architectureBadge, systemImage: viewModel.machine.architecture.symbolName)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(MFTheme.mistDim)
                .lineLimit(2)
            Text(viewModel.statusMessage)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(MFTheme.accent)
                .lineLimit(3)
            if let error = viewModel.lastError {
                Text(error)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(MFTheme.amber)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MFTheme.surface.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(MFTheme.line, lineWidth: 1)
        )
    }
}
