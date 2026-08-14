import SwiftUI

enum MFTheme {
    // Signal Night — deep navy + electric sky blue
    static let ink = Color(red: 0.027, green: 0.043, blue: 0.071)           // #070B12
    static let inkLift = Color(red: 0.051, green: 0.078, blue: 0.125)        // #0D1420
    static let canvas = Color(red: 0.071, green: 0.102, blue: 0.157)         // #121A28
    static let surface = Color(red: 0.094, green: 0.133, blue: 0.200)        // #182233
    static let surfaceLift = Color(red: 0.129, green: 0.188, blue: 0.267)    // #213044
    static let line = Color.white.opacity(0.07)
    static let lineStrong = Color.white.opacity(0.12)

    /// Primary accent (signal sky blue)
    static let accent = Color(red: 0.310, green: 0.612, blue: 1.000)         // #4F9CFF
    static let accentSoft = Color(red: 0.310, green: 0.612, blue: 1.000).opacity(0.14)
    static let accentDeep = Color(red: 0.180, green: 0.420, blue: 0.769)     // #2E6BC4
    /// Compat alias used across views
    static let mint = accent
    static let mintDeep = accentDeep

    static let amber = Color(red: 0.878, green: 0.639, blue: 0.353)          // #E0A35A
    static let coral = Color(red: 0.878, green: 0.478, blue: 0.416)          // #E07A6A
    static let sand = Color(red: 0.933, green: 0.949, blue: 0.973)           // #EEF2F8
    static let mist = Color(red: 0.545, green: 0.592, blue: 0.671)           // #8B97AB
    static let mistDim = Color(red: 0.400, green: 0.447, blue: 0.529)        // #667287

    static let cool = accent
    static let warm = Color(red: 0.820, green: 0.730, blue: 0.420)
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
