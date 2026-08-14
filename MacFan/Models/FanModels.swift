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
        case .automatic: return "系统自动"
        case .manual: return "手动调节"
        case .maximum: return "最大转速"
        case .scene: return "场景模式"
        }
    }

    var subtitle: String {
        switch self {
        case .automatic: return "交还给 macOS SMC 温控"
        case .manual: return "逐风扇精确设定 RPM"
        case .maximum: return "立即拉满全部风扇"
        case .scene: return "按场景与温度曲线运行"
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
        case .cool: return "凉爽"
        case .warm: return "适中"
        case .hot: return "偏热"
        case .critical: return "过热"
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
        case .silentOffice: return "静音办公"
        case .mediaLounge: return "影音观影"
        case .creatorBurst: return "创作渲染"
        case .gameArena: return "游戏竞技"
        case .arcticMax: return "极速散热"
        case .nightOwl: return "夜间静音"
        case .custom: return "自定义"
        }
    }

    var blurb: String {
        switch self {
        case .silentOffice: return "键盘低噪，适合文档与会议"
        case .mediaLounge: return "优先安静，温度略升也可接受"
        case .creatorBurst: return "导出/编译时主动加压散热"
        case .gameArena: return "保持高风量，压制帧率掉温"
        case .arcticMax: return "全风扇最大，极限降温"
        case .nightOwl: return "深夜自动压低转速"
        case .custom: return "你自己的曲线与联动规则"
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
