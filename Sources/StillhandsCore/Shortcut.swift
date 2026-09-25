public struct Shortcut: Codable, Hashable, Sendable {
    public var keyCode: UInt16
    public var modifiers: Modifiers

    public init(keyCode: UInt16, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public init(_ key: String, _ modifiers: Modifiers) {
        self.init(keyCode: KeyNames.code(for: key)!, modifiers: modifiers)
    }

    public var keyName: String { KeyNames.name(for: keyCode) ?? "Key \(keyCode)" }
    public var keycaps: [String] { modifiers.symbols + [keyName] }
    public var display: String { keycaps.joined() }

    public func matches(keyCode: UInt16, cgFlags: UInt64) -> Bool {
        keyCode == self.keyCode && Modifiers(cgFlags: cgFlags) == modifiers
    }

    public enum Invalid: Error, Equatable {
        case tooFewModifiers, reserved, unsupportedKey
    }

    public func validate() -> Invalid? {
        if modifiers.count < 2 { return .tooFewModifiers }
        if KeyNames.name(for: keyCode) == nil || keyCode == KeyNames.escape { return .unsupportedKey }
        if Self.reserved.contains(self) { return .reserved }
        return nil
    }

    public static let reserved: Set<Shortcut> = [
        Shortcut("Q", [.control, .command]),
        Shortcut("F", [.control, .command]),
        Shortcut("Space", [.control, .command]),
        Shortcut("Space", [.command]),
        Shortcut("Space", [.control]),
        Shortcut("⎋", [.option, .command]),
        Shortcut("⎋", [.option, .shift, .command]),
        Shortcut("3", [.shift, .command]),
        Shortcut("4", [.shift, .command]),
        Shortcut("5", [.shift, .command]),
        Shortcut("6", [.shift, .command]),
        Shortcut("3", [.control, .shift, .command]),
        Shortcut("4", [.control, .shift, .command]),
        Shortcut("5", [.control, .shift, .command]),
        Shortcut("D", [.option, .command]),
        Shortcut("Q", [.shift, .command]),
        Shortcut("Q", [.option, .shift, .command]),
        Shortcut(".", [.shift, .command]),
        Shortcut("/", [.shift, .command]),
        Shortcut("8", [.control, .option, .command]),
        Shortcut(",", [.control, .option, .command]),
        Shortcut(".", [.control, .option, .command]),
        Shortcut("V", [.option, .shift, .command]),
    ]

    static let randomModifierSets: [Modifiers] = [
        [.control, .option, .command],
        [.control, .option, .shift],
        [.control, .shift, .command],
        [.option, .shift, .command],
    ]

    public static func random<G: RandomNumberGenerator>(using g: inout G) -> Shortcut {
        while true {
            let s = Shortcut(
                keyCode: KeyNames.randomPool.randomElement(using: &g)!,
                modifiers: randomModifierSets.randomElement(using: &g)!
            )
            if s.validate() == nil { return s }
        }
    }

    public static func random() -> Shortcut {
        var g = SystemRandomNumberGenerator()
        return random(using: &g)
    }
}
