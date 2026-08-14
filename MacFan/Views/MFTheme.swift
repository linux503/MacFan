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
    let coolMint: Color
    let warm: Color
    let atmosphereBottom: Color
    let hoverWash: Color

    /// Arctic Ice Night — charcoal steel + ice cyan, heat in amber/coral
    static let dark = ThemePalette(
        ink: Color(red: 0.020, green: 0.035, blue: 0.051),          // #05090D
        inkLift: Color(red: 0.043, green: 0.078, blue: 0.098),       // #0B1419
        canvas: Color(red: 0.063, green: 0.102, blue: 0.125),        // #101A20
        surface: Color(red: 0.086, green: 0.133, blue: 0.157),       // #162228
        surfaceLift: Color(red: 0.118, green: 0.180, blue: 0.212),   // #1E2E36
        line: Color.white.opacity(0.07),
        lineStrong: Color.white.opacity(0.13),
        accent: Color(red: 0.243, green: 0.784, blue: 0.863),        // #3EC8DC
        accentSoft: Color(red: 0.243, green: 0.784, blue: 0.863).opacity(0.14),
        accentDeep: Color(red: 0.102, green: 0.561, blue: 0.639),    // #1A8FA3
        amber: Color(red: 0.910, green: 0.659, blue: 0.361),         // #E8A85C
        coral: Color(red: 0.878, green: 0.447, blue: 0.384),         // #E07262
        sand: Color(red: 0.933, green: 0.965, blue: 0.973),          // #EEF6F8
        mist: Color(red: 0.541, green: 0.604, blue: 0.643),          // #8A9AA4
        mistDim: Color(red: 0.400, green: 0.463, blue: 0.502),       // #667680
        coolMint: Color(red: 0.369, green: 0.812, blue: 0.722),      // #5ECFB8
        warm: Color(red: 0.850, green: 0.710, blue: 0.380),
        atmosphereBottom: Color(red: 0.016, green: 0.027, blue: 0.043),
        hoverWash: Color.white.opacity(0.045)
    )

    /// Arctic Ice Day — ice paper + teal-cyan (not cream / terracotta / purple)
    static let light = ThemePalette(
        ink: Color(red: 0.949, green: 0.969, blue: 0.973),           // #F2F7F8
        inkLift: Color(red: 1.000, green: 1.000, blue: 1.000),       // #FFFFFF
        canvas: Color(red: 0.902, green: 0.941, blue: 0.949),        // #E6F0F2
        surface: Color(red: 1.000, green: 1.000, blue: 1.000),       // #FFFFFF
        surfaceLift: Color(red: 0.863, green: 0.925, blue: 0.937),   // #DCECF0
        line: Color.black.opacity(0.07),
        lineStrong: Color.black.opacity(0.13),
        accent: Color(red: 0.055, green: 0.541, blue: 0.604),        // #0E8A9A
        accentSoft: Color(red: 0.055, green: 0.541, blue: 0.604).opacity(0.12),
        accentDeep: Color(red: 0.039, green: 0.420, blue: 0.471),    // #0A6B78
        amber: Color(red: 0.784, green: 0.533, blue: 0.196),         // #C88832
        coral: Color(red: 0.831, green: 0.353, blue: 0.322),         // #D45A52
        sand: Color(red: 0.047, green: 0.094, blue: 0.133),          // #0C1822
        mist: Color(red: 0.353, green: 0.427, blue: 0.463),          // #5A6D76
        mistDim: Color(red: 0.478, green: 0.549, blue: 0.580),       // #7A8C94
        coolMint: Color(red: 0.165, green: 0.604, blue: 0.510),      // #2A9A82
        warm: Color(red: 0.745, green: 0.580, blue: 0.235),
        atmosphereBottom: Color(red: 0.878, green: 0.941, blue: 0.949),
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
    @MainActor static var cool: Color { p.coolMint }
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
                    .fill(
                        LinearGradient(
                            colors: [MFTheme.surface.opacity(0.96), MFTheme.canvas.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
