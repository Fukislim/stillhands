import Foundation
import StillhandsCore

final class AppState: ObservableObject {
    private let store: UserDefaults?

    @Published var shortcut: Shortcut { didSet { save(try? JSONEncoder().encode(shortcut), "shortcut") } }
    @Published var lockKeyboard: Bool { didSet { save(lockKeyboard, "lockKeyboard") } }
    @Published var lockClicks: Bool { didSet { save(lockClicks, "lockClicks") } }
    @Published var lockPointer: Bool { didSet { save(lockPointer, "lockPointer") } }
    @Published var blackOut: Bool { didSet { save(blackOut, "blackOut") } }
    @Published var autoUnlockMinutes: Int { didSet { save(autoUnlockMinutes, "autoUnlockMinutes") } }
    @Published var iconStyle: IconStyle { didSet { save(iconStyle.rawValue, "iconStyle") } }
    @Published var didOnboard: Bool { didSet { save(didOnboard, "didOnboard") } }

    @Published var isLocked = false
    @Published var autoUnlockAt: Date?
    @Published var axTrusted = false
    @Published var tapError: String?
    @Published var isRecording = false
    @Published var launchAtLogin = false
    @Published var loginError: String?

    static let autoUnlockOptions = [0, 5, 15, 30, 60]

    init(store: UserDefaults?) {
        self.store = store
        let saved = store?.data(forKey: "shortcut").flatMap { try? JSONDecoder().decode(Shortcut.self, from: $0) }
        shortcut = saved ?? .random()
        lockKeyboard = store?.object(forKey: "lockKeyboard") as? Bool ?? true
        lockClicks = store?.object(forKey: "lockClicks") as? Bool ?? true
        lockPointer = store?.object(forKey: "lockPointer") as? Bool ?? true
        blackOut = store?.object(forKey: "blackOut") as? Bool ?? false
        autoUnlockMinutes = store?.object(forKey: "autoUnlockMinutes") as? Int ?? 30
        iconStyle = store?.string(forKey: "iconStyle").flatMap(IconStyle.init(rawValue:)) ?? .hand
        didOnboard = store?.bool(forKey: "didOnboard") ?? false
        if saved == nil { save(try? JSONEncoder().encode(shortcut), "shortcut") }
    }

    var activeCategories: Set<InputCategory> {
        var c: Set<InputCategory> = []
        if lockKeyboard { c.insert(.keyboard) }
        if lockClicks { c.insert(.clicks) }
        if lockPointer { c.insert(.pointer) }
        return c
    }

    var canLock: Bool { axTrusted && tapError == nil && !activeCategories.isEmpty }

    private func save(_ value: Any?, _ key: String) {
        store?.set(value, forKey: key)
    }
}
