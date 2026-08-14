import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case zhHans = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHans: return "中文"
        case .english: return "English"
        }
    }
}

@MainActor
@Observable
final class LocalizationStore {
    static let shared = LocalizationStore()

    private static let defaultsKey = "macfan.appLanguage"

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.defaultsKey)
        }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.defaultsKey),
           let lang = AppLanguage(rawValue: raw) {
            language = lang
        } else {
            // Product default: Chinese, regardless of system language.
            language = .zhHans
            UserDefaults.standard.set(AppLanguage.zhHans.rawValue, forKey: Self.defaultsKey)
        }
    }

    func t(_ key: String) -> String {
        L10n.string(key, language: language)
    }

    func toggle() {
        language = (language == .zhHans) ? .english : .zhHans
    }
}

enum AppLinks {
    static let website = URL(string: "https://linux503.github.io/MacFan/")!
    static let github = URL(string: "https://github.com/linux503/MacFan")!
    static let versionManifest = URL(string: "https://linux503.github.io/MacFan/version.json")!
    static let githubLatestRelease = URL(string: "https://api.github.com/repos/linux503/MacFan/releases/latest")!
}

enum L10n {
    private static let defaultsKey = "macfan.appLanguage"

    static var currentLanguage: AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: defaultsKey),
           let lang = AppLanguage(rawValue: raw) {
            return lang
        }
        return .zhHans
    }

    static func t(_ key: String) -> String {
        string(key, language: currentLanguage)
    }

    static func string(_ key: String, language: AppLanguage) -> String {
        let table = language == .english ? english : chinese
        return table[key] ?? english[key] ?? key
    }

    private static let chinese: [String: String] = [
        "brand.tagline": "精准风控 · Intel / Apple Silicon",
        "section.control": "控制模式",
        "section.extensions": "扩展",
        "section.more": "更多",
        "section.scenes": "特色场景",
        "section.fans": "风扇",
        "section.thermal": "温度轨迹",
        "toggle.appLink": "应用联动",
        "toggle.schedule": "夜间调度",
        "admin.title": "需要管理员权限",
        "admin.body": "写入 SMC 需要管理员权限。请先把 MacFan 拖到「应用程序」，再点授权（无需重启应用）。",
        "admin.button": "授权管理员权限",
        "admin.authorizing": "正在请求管理员密码…",
        "admin.passwordHint": "请在系统密码框中输入密码；若没看到，可能被挡在其他窗口后面。",
        "admin.failed": "管理员授权失败",
        "admin.canceled": "已取消密码输入",
        "admin.helperNotReady": "授权成功但助手未就绪，请重试。",
        "admin.missingExe": "找不到 MacFan 可执行文件",
        "language": "语言",
        "language.zh": "中文",
        "language.en": "English",
        "appearance": "外观",
        "appearance.dark": "深色",
        "appearance.light": "浅色",
        "update.check": "检查更新",
        "update.checking": "正在检查更新…",
        "update.latest": "已是最新版本（%@）",
        "update.available": "发现新版本 %@（当前 %@）",
        "update.failed": "检查更新失败，请检查网络后重试。",
        "update.openSite": "打开官网",
        "update.openRelease": "查看发布页",
        "update.later": "稍后",
        "website": "访问官网",
        "github": "GitHub",
        "metric.cpu": "CPU",
        "metric.gpu": "GPU",
        "metric.enclosure": "机身",
        "metric.thermal": "热况",
        "fan.maxLocked": "最大转速已锁定",
        "menubar.max": "最大转速",
        "menubar.auto": "系统自动",
        "menubar.silent": "静音办公",
        "mode.automatic": "系统自动",
        "mode.automatic.sub": "交还给 macOS SMC 温控",
        "mode.manual": "手动调节",
        "mode.manual.sub": "逐风扇精确设定 RPM",
        "mode.maximum": "最大转速",
        "mode.maximum.sub": "立即拉满全部风扇",
        "mode.scene": "场景模式",
        "mode.scene.sub": "按场景与温度曲线运行",
        "scene.silentOffice": "静音办公",
        "scene.silentOffice.blurb": "键盘低噪，适合文档与会议",
        "scene.mediaLounge": "影音观影",
        "scene.mediaLounge.blurb": "优先安静，温度略升也可接受",
        "scene.creatorBurst": "创作渲染",
        "scene.creatorBurst.blurb": "导出/编译时主动加压散热",
        "scene.gameArena": "游戏竞技",
        "scene.gameArena.blurb": "保持高风量，压制帧率掉温",
        "scene.arcticMax": "极速散热",
        "scene.arcticMax.blurb": "全风扇最大，极限降温",
        "scene.nightOwl": "夜间静音",
        "scene.nightOwl.blurb": "深夜自动压低转速",
        "scene.custom": "自定义",
        "scene.custom.blurb": "你自己的曲线与联动规则",
        "severity.cool": "凉爽",
        "severity.warm": "适中",
        "severity.hot": "偏热",
        "severity.critical": "过热",
        "status.probing": "正在探测风扇…",
        "status.liveAdmin": "实机控制已启用（管理员）",
        "status.liveNeedAdmin": "已读到真实风扇，但写入需要管理员权限",
        "status.preview": "未读到 SMC 风扇，当前为预览数据",
        "status.initFailed": "初始化失败",
        "status.auto": "已恢复系统自动温控",
        "status.max": "全部风扇已设为最大转速",
        "status.manual": "手动模式：拖动滑杆调节单风扇",
        "status.scene": "场景「%@」· 目标 %d%%",
        "status.fanSet": "已设定 %@ → %d RPM",
        "error.needAdminHint": "点击下方按钮，输入密码授权后即可真正调速。",
        "error.privilege": "需要管理员权限才能修改真实风扇转速。请点击「授权管理员权限」。",
        "error.smc": "SMC 不可用：%@",
        "error.fanMissing": "未找到风扇：%@",
        "error.unsupported": "当前机型暂不支持直接写入风扇转速。",
        "currentVersion": "当前版本 %@",
        "alert.updateTitle": "检查更新",
        "ok": "好",
        "chart.cpu": "CPU",
        "chart.gpu": "GPU"
    ]

    private static let english: [String: String] = [
        "brand.tagline": "Precise cooling · Intel / Apple Silicon",
        "section.control": "Control",
        "section.extensions": "Extensions",
        "section.more": "More",
        "section.scenes": "Scenes",
        "section.fans": "Fans",
        "section.thermal": "Thermal Trail",
        "toggle.appLink": "App linking",
        "toggle.schedule": "Night schedule",
        "admin.title": "Administrator required",
        "admin.body": "Writing SMC needs admin rights. Enter your password once — the app stays open.",
        "admin.button": "Authorize Administrator",
        "admin.authorizing": "Requesting administrator password…",
        "admin.passwordHint": "Enter your password in the system dialog. If you don’t see it, it may be behind another window.",
        "admin.failed": "Administrator authorization failed",
        "admin.canceled": "Password prompt was canceled",
        "admin.helperNotReady": "Authorized, but the helper did not start. Please try again.",
        "admin.missingExe": "MacFan executable not found",
        "language": "Language",
        "language.zh": "中文",
        "language.en": "English",
        "appearance": "Appearance",
        "appearance.dark": "Dark",
        "appearance.light": "Light",
        "update.check": "Check for Updates",
        "update.checking": "Checking for updates…",
        "update.latest": "You’re up to date (%@)",
        "update.available": "Update %@ available (current %@)",
        "update.failed": "Update check failed. Please check your network.",
        "update.openSite": "Open Website",
        "update.openRelease": "View Release",
        "update.later": "Later",
        "website": "Website",
        "github": "GitHub",
        "metric.cpu": "CPU",
        "metric.gpu": "GPU",
        "metric.enclosure": "Chassis",
        "metric.thermal": "Thermal",
        "fan.maxLocked": "Max speed locked",
        "menubar.max": "Max Speed",
        "menubar.auto": "System Auto",
        "menubar.silent": "Silent Office",
        "mode.automatic": "System Auto",
        "mode.automatic.sub": "Hand control back to macOS SMC",
        "mode.manual": "Manual",
        "mode.manual.sub": "Set target RPM per fan",
        "mode.maximum": "Max Speed",
        "mode.maximum.sub": "Push every fan to maximum",
        "mode.scene": "Scene Mode",
        "mode.scene.sub": "Follow scene temperature curves",
        "scene.silentOffice": "Silent Office",
        "scene.silentOffice.blurb": "Low noise for docs and meetings",
        "scene.mediaLounge": "Media Lounge",
        "scene.mediaLounge.blurb": "Quiet first, mild heat OK",
        "scene.creatorBurst": "Creator Burst",
        "scene.creatorBurst.blurb": "Boost cooling while exporting/compiling",
        "scene.gameArena": "Game Arena",
        "scene.gameArena.blurb": "High airflow to fight frame drops",
        "scene.arcticMax": "Arctic Max",
        "scene.arcticMax.blurb": "All fans at maximum",
        "scene.nightOwl": "Night Owl",
        "scene.nightOwl.blurb": "Quieter overnight curve",
        "scene.custom": "Custom",
        "scene.custom.blurb": "Your own curve and app rules",
        "severity.cool": "Cool",
        "severity.warm": "Warm",
        "severity.hot": "Hot",
        "severity.critical": "Critical",
        "status.probing": "Probing fans…",
        "status.liveAdmin": "Live control enabled (admin)",
        "status.liveNeedAdmin": "Fans detected; writes need administrator",
        "status.preview": "No SMC fans found — preview data",
        "status.initFailed": "Initialization failed",
        "status.auto": "Restored system automatic control",
        "status.max": "All fans set to maximum",
        "status.manual": "Manual mode: drag sliders per fan",
        "status.scene": "Scene “%@” · target %d%%",
        "status.fanSet": "Set %@ → %d RPM",
        "error.needAdminHint": "Tap the button below and enter your password to enable live fan control.",
        "error.privilege": "Administrator rights are required to change fan targets. Tap “Authorize Administrator”.",
        "error.smc": "SMC unavailable: %@",
        "error.fanMissing": "Fan not found: %@",
        "error.unsupported": "This Mac does not support direct fan writes yet.",
        "currentVersion": "Version %@",
        "alert.updateTitle": "Updates",
        "ok": "OK",
        "chart.cpu": "CPU",
        "chart.gpu": "GPU"
    ]
}
