import AppKit
import Combine
import StillhandsCore

final class MenuBar: NSObject, NSMenuDelegate {
    struct Actions {
        var lock: () -> Void = {}
        var unlock: () -> Void = {}
        var openSettings: () -> Void = {}
    }

    let menu = NSMenu()
    private let state: AppState
    private let actions: Actions
    private var statusItem: NSStatusItem?
    private var iconRows: [NSSegmentedControl] = []
    private var bag: Set<AnyCancellable> = []

    init(state: AppState, actions: Actions) {
        self.state = state
        self.actions = actions
        super.init()
        menu.autoenablesItems = false
        menu.delegate = self
        rebuild()
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.menu = menu
        statusItem = item
        Publishers.CombineLatest4(state.$iconStyle, state.$isLocked, state.$axTrusted, state.$tapError)
            .sink { style, locked, trusted, error in
                item.button?.image = style.image(locked: locked, dimmed: !trusted || error != nil)
            }
            .store(in: &bag)
    }

    func menuNeedsUpdate(_ menu: NSMenu) { rebuild() }

    func rebuild() {
        menu.removeAllItems()
        let unlocked = !state.isLocked

        if !state.axTrusted || state.tapError != nil {
            menu.addItem(ActionItem("Grant Accessibility Access…", handler: SettingsWindow.openAccessibilitySettings))
            menu.addItem(.separator())
        }

        if unlocked {
            let lock = ActionItem("Lock Now", handler: actions.lock)
            if let (key, modifiers) = state.shortcut.menuKeyEquivalent {
                lock.keyEquivalent = key
                lock.keyEquivalentModifierMask = modifiers
            }
            lock.isEnabled = state.canLock
            menu.addItem(lock)
        } else {
            menu.addItem(ActionItem("Unlock", handler: actions.unlock))
            if let at = state.autoUnlockAt {
                menu.addItem(label("Auto-unlocks at \(at.formatted(date: .omitted, time: .shortened))"))
            }
        }

        menu.addItem(.separator())
        menu.addItem(header("Lock"))
        menu.addItem(toggle("Keyboard", \.lockKeyboard, enabled: unlocked))
        menu.addItem(toggle("Clicks & Scrolling", \.lockClicks, enabled: unlocked))
        menu.addItem(toggle("Pointer Movement", \.lockPointer, enabled: unlocked))
        menu.addItem(toggle("Black Out Screens", \.blackOut, enabled: unlocked))

        menu.addItem(.separator())
        menu.addItem(header("Menu Bar Icon"))
        menu.addItem(iconPicker())

        menu.addItem(.separator())
        let autoUnlock = NSMenuItem(title: "Auto-Unlock", action: nil, keyEquivalent: "")
        autoUnlock.isEnabled = unlocked
        autoUnlock.submenu = autoUnlockMenu()
        menu.addItem(autoUnlock)
        menu.addItem(ActionItem("Settings…", key: ",", handler: actions.openSettings))

        menu.addItem(.separator())
        menu.addItem(ActionItem("Quit Stillhands", key: "q") { NSApp.terminate(nil) })
    }

    private func header(_ title: String) -> NSMenuItem {
        if #available(macOS 14, *) { return .sectionHeader(title: title) }
        return label(title)
    }

    private func label(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func toggle(_ title: String, _ key: ReferenceWritableKeyPath<AppState, Bool>, enabled: Bool) -> NSMenuItem {
        let item = ActionItem(title) { [state] in state[keyPath: key].toggle() }
        item.state = state[keyPath: key] ? .on : .off
        item.isEnabled = enabled
        return item
    }

    private func iconPicker() -> NSMenuItem {
        iconRows = IconStyle.rows.map { styles in
            let control = NSSegmentedControl(images: styles.map(\.preview), trackingMode: .selectOne, target: self, action: #selector(pickIcon))
            control.segmentDistribution = .fillEqually
            control.selectedSegment = styles.firstIndex(of: state.iconStyle) ?? -1
            for (i, style) in styles.enumerated() { control.setToolTip(style.title, forSegment: i) }
            return control
        }
        let stack = NSStackView(views: iconRows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
        iconRows.dropFirst().forEach { $0.widthAnchor.constraint(equalTo: iconRows[0].widthAnchor).isActive = true }
        stack.frame.size = stack.fittingSize

        let item = NSMenuItem()
        item.view = stack
        return item
    }

    @objc private func pickIcon(_ sender: NSSegmentedControl) {
        guard let row = iconRows.firstIndex(of: sender) else { return }
        state.iconStyle = IconStyle.rows[row][sender.selectedSegment]
        iconRows.filter { $0 !== sender }.forEach { $0.selectedSegment = -1 }
    }

    private func autoUnlockMenu() -> NSMenu {
        let sub = NSMenu()
        for minutes in AppState.autoUnlockOptions {
            let item = ActionItem(minutes == 0 ? "Off" : "After \(minutes) Minutes") { [state] in
                state.autoUnlockMinutes = minutes
            }
            item.state = state.autoUnlockMinutes == minutes ? .on : .off
            sub.addItem(item)
        }
        return sub
    }
}

final class ActionItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func fire() { handler() }
}

extension Shortcut {
    var menuKeyEquivalent: (String, NSEvent.ModifierFlags)? {
        let special: [String: Int] = [
            "←": NSLeftArrowFunctionKey, "→": NSRightArrowFunctionKey,
            "↑": NSUpArrowFunctionKey, "↓": NSDownArrowFunctionKey,
        ]
        let key: String?
        switch keyName {
        case "Space": key = " "
        case "↩": key = "\r"
        case "⇥": key = "\t"
        case let name where special[name] != nil: key = String(UnicodeScalar(special[name]!)!)
        case let name where name.count > 1 && name.hasPrefix("F"):
            key = Int(name.dropFirst()).flatMap { UnicodeScalar(NSF1FunctionKey + $0 - 1) }.map(String.init)
        case let name where name.count == 1: key = name.lowercased()
        default: key = nil
        }
        return key.map { ($0, NSEvent.ModifierFlags(rawValue: UInt(modifiers.cgFlags))) }
    }
}
