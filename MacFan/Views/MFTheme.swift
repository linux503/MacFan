import SwiftUI
import Observation

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case dark
    case light

    var id: String { rawValue }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}

struct ThemePalette: Sendable {
    let ink: Color
    let inkLift: Color
    let canvas: Color
    let surface: Color
    let surfaceLift: Color
    let line: Color
    let lineStrong: Color
    let accent: Color
    let accentSoft: Color
    let accentDeep: Color
    let amber: Color
    let coral: Color
    let sand: Color
    let mist: Color
    let mistDim: Color
    let warm: Color
    let atmosphereBottom: Color
    let hoverWash: Color

    /// Signal Night — deep navy + electric sky blue
    static let dark = ThemePalette(
        ink: Color(red: 0.027, green: 0.043, blue: 0.071),          // #070B12
        inkLift: Color(red: 0.051, green: 0.078, blue: 0.125),       // #0D1420
        canvas: Color(red: 0.071, green: 0.102, blue: 0.157),        // #121A28
        surface: Color(red: 0.094, green: 0.133, blue: 0.200),       // #182233
        surfaceLift: Color(red: 0.129, green: 0.188, blue: 0.267),   // #213044
        line: Color.white.opacity(0.07),
        lineStrong: Color.white.opacity(0.12),
        accent: Color(red: 0.310, green: 0.612, blue: 1.000),        // #4F9CFF
        accentSoft: Color(red: 0.310, green: 0.612, blue: 1.000).opacity(0.14),
        accentDeep: Color(red: 0.180, green: 0.420, blue: 0.769),    // #2E6BC4
        amber: Color(red: 0.878, green: 0.639, blue: 0.353),         // #E0A35A
        coral: Color(red: 0.878, green: 0.478, blue: 0.416),         // #E07A6A
        sand: Color(red: 0.933, green: 0.949, blue: 0.973),          // #EEF2F8
        mist: Color(red: 0.545, green: 0.592, blue: 0.671),          // #8B97AB
        mistDim: Color(red: 0.400, green: 0.447, blue: 0.529),       // #667287
        warm: Color(red: 0.820, green: 0.730, blue: 0.420),
        atmosphereBottom: Color(red: 0.035, green: 0.050, blue: 0.090),
        hoverWash: Color.white.opacity(0.045)
    )

    /// Signal Day — cool paper + deeper sky blue (not cream / terracotta)
    static let light = ThemePalette(
        ink: Color(red: 0.953, green: 0.961, blue: 0.976),           // #F3F5F9
        inkLift: Color(red: 1.000, green: 1.000, blue: 1.000),       // #FFFFFF
        canvas: Color(red: 0.914, green: 0.929, blue: 0.953),        // #E9EDF3
        surface: Color(red: 1.000, green: 1.000, blue: 1.000),       // #FFFFFF
        surfaceLift: Color(red: 0.890, green: 0.914, blue: 0.953),   // #E3E9F3
        line: Color.black.opacity(0.08),
        lineStrong: Color.black.opacity(0.14),
        accent: Color(red: 0.145, green: 0.420, blue: 0.890),        // #256BE3
        accentSoft: Color(red: 0.145, green: 0.420, blue: 0.890).opacity(0.12),
        accentDeep: Color(red: 0.110, green: 0.320, blue: 0.700),    // #1C52B2
        amber: Color(red: 0.780, green: 0.520, blue: 0.180),         // #C7852E
        coral: Color(red: 0.820, green: 0.360, blue: 0.320),         // #D15C52
        sand: Color(red: 0.090, green: 0.118, blue: 0.180),          // #171E2E
        mist: Color(red: 0.380, green: 0.435, blue: 0.520),          // #616F85
        mistDim: Color(red: 0.520, green: 0.565, blue: 0.635),       // #8590A2
        warm: Color(red: 0.720, green: 0.580, blue: 0.220),
        atmosphereBottom: Color(red: 0.890, green: 0.910, blue: 0.945),
        hoverWash: Color.black.opacity(0.035)
    )
}

@MainActor
@Observable
final class ThemeStore {
    static let shared = ThemeStore()

    private static let defaultsKey = "macfan.appAppearance"

    var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.defaultsKey)
        }
    }

    var palette: ThemePalette {
        appearance == .light ? .light : .dark
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.defaultsKey),
           let value = AppAppearance(rawValue: raw) {
            appearance = value
        } else {
            appearance = .dark
        }
    }

    func toggle() {
        appearance = (appearance == .dark) ? .light : .dark
    }
}

enum MFTheme {
    @MainActor
    private static var p: ThemePalette { ThemeStore.shared.palette }

    @MainActor static var ink: Color { p.ink }
    @MainActor static var inkLift: Color { p.inkLift }
    @MainActor static var canvas: Color { p.canvas }
    @MainActor static var surface: Color { p.surface }
    @MainActor static var surfaceLift: Color { p.surfaceLift }
    @MainActor static var line: Color { p.line }
    @MainActor static var lineStrong: Color { p.lineStrong }
    @MainActor static var accent: Color { p.accent }
    @MainActor static var accentSoft: Color { p.accentSoft }
    @MainActor static var accentDeep: Color { p.accentDeep }
    @MainActor static var mint: Color { accent }
    @MainActor static var mintDeep: Color { accentDeep }
    @MainActor static var amber: Color { p.amber }
    @MainActor static var coral: Color { p.coral }
    @MainActor static var sand: Color { p.sand }
    @MainActor static var mist: Color { p.mist }
    @MainActor static var mistDim: Color { p.mistDim }
    @MainActor static var cool: Color { accent }
    @MainActor static var warm: Color { p.warm }
    @MainActor static var hot: Color { amber }
    @MainActor static var critical: Color { coral }
    @MainActor static var atmosphereBottom: Color { p.atmosphereBottom }
    @MainActor static var hoverWash: Color { p.hoverWash }

    @MainActor
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
                    .fill(MFTheme.surface.opacity(0.92))
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
        if hovering { return MFTheme.hoverWash }
        return .clear
    }

    private var strokeColor: Color {
        if selected { return MFTheme.accent.opacity(0.35) }
        if hovering { return MFTheme.lineStrong }
        return .clear
    }
}
