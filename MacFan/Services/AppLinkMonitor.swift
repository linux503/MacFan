import AppKit
import Foundation

@MainActor
final class AppLinkMonitor {
    private(set) var frontmostBundleID: String?
    private(set) var runningBundleIDs: Set<String> = []

    func refresh() {
        frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        runningBundleIDs = Set(
            NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        )
    }

    func matchedScene(from scenes: [FanScene]) -> FanScene? {
        refresh()
        // Prefer frontmost match, then any running match (creator/game first by priority order).
        if let front = frontmostBundleID {
            if let hit = scenes.first(where: { $0.linkedBundleIDs.contains(front) }) {
                return hit
            }
        }
        let priority: [FanSceneKind] = [.gameArena, .creatorBurst, .mediaLounge, .silentOffice]
        for kind in priority {
            if let scene = scenes.first(where: { $0.kind == kind }),
               scene.linkedBundleIDs.contains(where: { runningBundleIDs.contains($0) }) {
                return scene
            }
        }
        return nil
    }

    func activeScheduledScene(from scenes: [FanScene], now: Date = .now) -> FanScene? {
        let hour = Calendar.current.component(.hour, from: now)
        return scenes.first { scene in
            guard let start = scene.scheduleStartHour, let end = scene.scheduleEndHour else { return false }
            if start == end { return true }
            if start < end {
                return hour >= start && hour < end
            }
            // Overnight window e.g. 23–7
            return hour >= start || hour < end
        }
    }
}

enum MachineIdentity {
    static func profile() -> MachineProfile {
        let arch = ChipArchitecture.current
        let model = hardwareModel() ?? "Mac"
        let fans: Int
        switch arch {
        case .appleSilicon: fans = 2
        case .intel: fans = modelLocalizedFanHint(model)
        case .unknown: fans = 1
        }
        return MachineProfile(
            modelName: friendlyModelName(model),
            architecture: arch,
            fanCountHint: fans,
            supportsDirectSMCWrite: arch == .intel
        )
    }

    private static func hardwareModel() -> String? {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0, count: size)
        let result = sysctlbyname("hw.model", &buffer, &size, nil, 0)
        guard result == 0 else { return nil }
        return String(cString: buffer)
    }

    private static func friendlyModelName(_ raw: String) -> String {
        // Keep raw identifier visible for power users; UI can still show it.
        raw
            .replacingOccurrences(of: "MacBookPro", with: "MacBook Pro ")
            .replacingOccurrences(of: "MacBookAir", with: "MacBook Air ")
            .replacingOccurrences(of: "Macmini", with: "Mac mini ")
            .replacingOccurrences(of: "MacPro", with: "Mac Pro ")
            .replacingOccurrences(of: "iMac", with: "iMac ")
            .replacingOccurrences(of: "Mac", with: "Mac ")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func modelLocalizedFanHint(_ model: String) -> Int {
        if model.contains("MacBook") { return 2 }
        if model.contains("MacPro") { return 3 }
        if model.contains("iMac") { return 2 }
        return 2
    }
}
