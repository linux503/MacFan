import Foundation

enum ChipArchitecture: String, Codable, Sendable {
    case appleSilicon = "Apple Silicon"
    case intel = "Intel"
    case unknown = "Unknown"

    static var current: ChipArchitecture {
        #if arch(arm64)
        return .appleSilicon
        #elseif arch(x86_64)
        return .intel
        #else
        return .unknown
        #endif
    }

    var symbolName: String {
        switch self {
        case .appleSilicon: return "cpu"
        case .intel: return "memorychip"
        case .unknown: return "questionmark.circle"
        }
    }
}

enum FanControlMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case automatic
    case manual
    case maximum
    case scene

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return L10n.t("mode.automatic")
        case .manual: return L10n.t("mode.manual")
        case .maximum: return L10n.t("mode.maximum")
        case .scene: return L10n.t("mode.scene")
        }
    }

    var subtitle: String {
        switch self {
        case .automatic: return L10n.t("mode.automatic.sub")
        case .manual: return L10n.t("mode.manual.sub")
        case .maximum: return L10n.t("mode.maximum.sub")
        case .scene: return L10n.t("mode.scene.sub")
        }
    }

    var symbolName: String {
        switch self {
        case .automatic: return "gearshape.2"
        case .manual: return "slider.horizontal.3"
        case .maximum: return "bolt.fill"
        case .scene: return "sparkles"
        }
    }
}

struct FanInfo: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var currentRPM: Double
    var targetRPM: Double
    var minRPM: Double
    var maxRPM: Double
    var isManual: Bool

    var normalizedSpeed: Double {
        guard maxRPM > minRPM else { return 0 }
        return min(1, max(0, (currentRPM - minRPM) / (maxRPM - minRPM)))
    }

    var percentLabel: String {
        "\(Int((normalizedSpeed * 100).rounded()))%"
    }
}

struct ThermalReading: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    var cpuCelsius: Double
    var gpuCelsius: Double
    var enclosureCelsius: Double

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        cpuCelsius: Double,
        gpuCelsius: Double,
        enclosureCelsius: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.cpuCelsius = cpuCelsius
        self.gpuCelsius = gpuCelsius
        self.enclosureCelsius = enclosureCelsius
    }

    var peakCelsius: Double {
        max(cpuCelsius, gpuCelsius, enclosureCelsius)
    }
}

enum ThermalSeverity: String, Sendable {
    case cool, warm, hot, critical

    init(celsius: Double) {
        switch celsius {
        case ..<55: self = .cool
        case ..<72: self = .warm
        case ..<88: self = .hot
        default: self = .critical
        }
    }

    var title: String {
        switch self {
        case .cool: return L10n.t("severity.cool")
        case .warm: return L10n.t("severity.warm")
        case .hot: return L10n.t("severity.hot")
        case .critical: return L10n.t("severity.critical")
        }
    }
}

struct TemperatureCurvePoint: Identifiable, Hashable, Codable, Sendable {
    var id: UUID
    var temperature: Double
    var fanPercent: Double

    init(id: UUID = UUID(), temperature: Double, fanPercent: Double) {
        self.id = id
        self.temperature = temperature
        self.fanPercent = fanPercent
    }
}

enum FanSceneKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case silentOffice
    case mediaLounge
    case creatorBurst
    case gameArena
    case arcticMax
    case nightOwl
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .silentOffice: return L10n.t("scene.silentOffice")
        case .mediaLounge: return L10n.t("scene.mediaLounge")
        case .creatorBurst: return L10n.t("scene.creatorBurst")
        case .gameArena: return L10n.t("scene.gameArena")
        case .arcticMax: return L10n.t("scene.arcticMax")
        case .nightOwl: return L10n.t("scene.nightOwl")
        case .custom: return L10n.t("scene.custom")
        }
    }

    var blurb: String {
        switch self {
        case .silentOffice: return L10n.t("scene.silentOffice.blurb")
        case .mediaLounge: return L10n.t("scene.mediaLounge.blurb")
        case .creatorBurst: return L10n.t("scene.creatorBurst.blurb")
        case .gameArena: return L10n.t("scene.gameArena.blurb")
        case .arcticMax: return L10n.t("scene.arcticMax.blurb")
        case .nightOwl: return L10n.t("scene.nightOwl.blurb")
        case .custom: return L10n.t("scene.custom.blurb")
        }
    }

    var symbolName: String {
        switch self {
        case .silentOffice: return "building.2"
        case .mediaLounge: return "play.rectangle"
        case .creatorBurst: return "paintbrush.pointed"
        case .gameArena: return "gamecontroller"
        case .arcticMax: return "snowflake"
        case .nightOwl: return "moon.stars"
        case .custom: return "slider.horizontal.2.square"
        }
    }

    var defaultCurve: [TemperatureCurvePoint] {
        switch self {
        case .silentOffice:
            return [
                .init(temperature: 40, fanPercent: 0.12),
                .init(temperature: 55, fanPercent: 0.22),
                .init(temperature: 70, fanPercent: 0.40),
                .init(temperature: 85, fanPercent: 0.65)
            ]
        case .mediaLounge:
            return [
                .init(temperature: 40, fanPercent: 0.10),
                .init(temperature: 60, fanPercent: 0.25),
                .init(temperature: 75, fanPercent: 0.45),
                .init(temperature: 90, fanPercent: 0.70)
            ]
        case .creatorBurst:
            return [
                .init(temperature: 40, fanPercent: 0.30),
                .init(temperature: 55, fanPercent: 0.50),
                .init(temperature: 70, fanPercent: 0.75),
                .init(temperature: 85, fanPercent: 0.95)
            ]
        case .gameArena:
            return [
                .init(temperature: 40, fanPercent: 0.45),
                .init(temperature: 55, fanPercent: 0.65),
                .init(temperature: 70, fanPercent: 0.85),
                .init(temperature: 85, fanPercent: 1.00)
            ]
        case .arcticMax:
            return [
                .init(temperature: 30, fanPercent: 1.00),
                .init(temperature: 90, fanPercent: 1.00)
            ]
        case .nightOwl:
            return [
                .init(temperature: 40, fanPercent: 0.08),
                .init(temperature: 60, fanPercent: 0.18),
                .init(temperature: 75, fanPercent: 0.35),
                .init(temperature: 88, fanPercent: 0.55)
            ]
        case .custom:
            return [
                .init(temperature: 40, fanPercent: 0.20),
                .init(temperature: 65, fanPercent: 0.45),
                .init(temperature: 80, fanPercent: 0.75),
                .init(temperature: 90, fanPercent: 1.00)
            ]
        }
    }
}

struct FanScene: Identifiable, Hashable, Codable, Sendable {
    var id: UUID
    var kind: FanSceneKind
    var name: String
    var curve: [TemperatureCurvePoint]
    var linkedBundleIDs: [String]
    var scheduleStartHour: Int?
    var scheduleEndHour: Int?

    init(
        id: UUID = UUID(),
        kind: FanSceneKind,
        name: String? = nil,
        curve: [TemperatureCurvePoint]? = nil,
        linkedBundleIDs: [String] = [],
        scheduleStartHour: Int? = nil,
        scheduleEndHour: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name ?? kind.title
        self.curve = curve ?? kind.defaultCurve
        self.linkedBundleIDs = linkedBundleIDs
        self.scheduleStartHour = scheduleStartHour
        self.scheduleEndHour = scheduleEndHour
    }

    static let builtIn: [FanScene] = [
        FanScene(kind: .silentOffice, linkedBundleIDs: ["com.microsoft.Word", "com.apple.iWork.Pages", "com.tinyspeck.slackmacgap"]),
        FanScene(kind: .mediaLounge, linkedBundleIDs: ["com.apple.TV", "com.netflix.Netflix", "com.colliderli.iina"]),
        FanScene(kind: .creatorBurst, linkedBundleIDs: ["com.apple.dt.Xcode", "com.apple.FinalCut", "com.adobe.Photoshop"]),
        FanScene(kind: .gameArena, linkedBundleIDs: ["com.valvesoftware.steam", "com.epicgames.EpicGamesLauncher"]),
        FanScene(kind: .arcticMax),
        FanScene(kind: .nightOwl, scheduleStartHour: 23, scheduleEndHour: 7)
    ]

    func fanPercent(for temperature: Double) -> Double {
        let sorted = curve.sorted { $0.temperature < $1.temperature }
        guard let first = sorted.first, let last = sorted.last else { return 0.4 }
        if temperature <= first.temperature { return first.fanPercent }
        if temperature >= last.temperature { return last.fanPercent }
        for index in 0..<(sorted.count - 1) {
            let a = sorted[index]
            let b = sorted[index + 1]
            if temperature >= a.temperature && temperature <= b.temperature {
                let t = (temperature - a.temperature) / max(0.001, b.temperature - a.temperature)
                return a.fanPercent + (b.fanPercent - a.fanPercent) * t
            }
        }
        return last.fanPercent
    }
}

struct MachineProfile: Sendable {
    let modelName: String
    let architecture: ChipArchitecture
    let fanCountHint: Int
    let supportsDirectSMCWrite: Bool
}
