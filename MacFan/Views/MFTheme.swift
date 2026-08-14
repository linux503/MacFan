import SwiftUI

enum MFTheme {
    // Graphite + muted ice — quieter than neon mint
    static let ink = Color(red: 0.059, green: 0.067, blue: 0.082)           // #0F1115
    static let inkLift = Color(red: 0.086, green: 0.098, blue: 0.118)        // #16191E
    static let canvas = Color(red: 0.110, green: 0.122, blue: 0.145)         // #1C1F25
    static let surface = Color(red: 0.133, green: 0.149, blue: 0.176)        // #22262D
    static let surfaceLift = Color(red: 0.165, green: 0.184, blue: 0.216)    // #2A2F37
    static let line = Color.white.opacity(0.06)
    static let lineStrong = Color.white.opacity(0.10)

    /// Primary accent (muted ice teal)
    static let accent = Color(red: 0.455, green: 0.690, blue: 0.675)         // #74B0AC
    static let accentSoft = Color(red: 0.455, green: 0.690, blue: 0.675).opacity(0.14)
    static let accentDeep = Color(red: 0.290, green: 0.455, blue: 0.447)     // #4A7472
    /// Compat alias used across views
    static let mint = accent
    static let mintDeep = accentDeep

    static let amber = Color(red: 0.780, green: 0.620, blue: 0.400)          // #C79E66
    static let coral = Color(red: 0.820, green: 0.450, blue: 0.420)          // #D1736B
    static let sand = Color(red: 0.945, green: 0.949, blue: 0.961)           // #F1F2F5
    static let mist = Color(red: 0.565, green: 0.592, blue: 0.647)           // #9097A5
    static let mistDim = Color(red: 0.420, green: 0.443, blue: 0.494)        // #6B717E

    static let cool = accent
    static let warm = Color(red: 0.820, green: 0.710, blue: 0.420)
    static let hot = amber
    static let critical = coral

    static func thermal(_ celsius: Double) -> Color {
        switch ThermalSeverity(celsius: celsius) {
        case .cool: return cool
        case .warm: return warm
        case .hot: return hot
        case .critical: return critical
        }
    }

    static func brandFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func displayFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

struct MFSectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(MFTheme.mistDim)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(MFTheme.accent)
            }
        }
        .padding(.bottom, 2)
    }
}

struct MFPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MFTheme.surface.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MFTheme.line, lineWidth: 1)
            )
    }
}

struct MFMenuButtonStyle: ButtonStyle {
    var selected: Bool = false
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        MFMenuButtonBody(
            configuration: configuration,
            selected: selected,
            compact: compact
        )
    }
}

private struct MFMenuButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let selected: Bool
    let compact: Bool
    @State private var hovering = false

    var body: some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, compact ? 8 : 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.14), value: hovering)
            .animation(.easeOut(duration: 0.12), value: selected)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .onHover { hovering = $0 }
    }

    private var fillColor: Color {
        if selected { return MFTheme.surfaceLift }
        if configuration.isPressed { return MFTheme.surface }
        if hovering { return Color.white.opacity(0.045) }
        return .clear
    }

    private var strokeColor: Color {
        if selected { return MFTheme.accent.opacity(0.35) }
        if hovering { return MFTheme.lineStrong }
        return .clear
    }
}
