public enum InputCategory: String, CaseIterable, Codable, Sendable {
    case keyboard, clicks, pointer
}

public enum EventKind: Equatable, Sendable {
    case keyDown(keyCode: UInt16, flags: UInt64, autorepeat: Bool)
    case keyUp(keyCode: UInt16)
    case flagsChanged
    case systemDefined(subtype: Int16)
    case pointerMove
    case click
    case scroll
    case gesture
    case other
}

public enum Decision: Equatable, Sendable {
    case pass, swallow, toggle, block, blockAndWarp
}

public struct EventPolicy: Sendable {
    public static let mediaKeySubtype: Int16 = 8

    public var shortcut: Shortcut
    public var isLocked = false
    public var active: Set<InputCategory> = []
    public var isRecording = false
    var swallowKeyUp: UInt16?

    public init(shortcut: Shortcut) { self.shortcut = shortcut }

    public mutating func decide(_ event: EventKind) -> Decision {
        switch event {
        case let .keyDown(code, flags, autorepeat)
            where !isRecording && shortcut.matches(keyCode: code, cgFlags: flags):
            if autorepeat { return .swallow }
            swallowKeyUp = code
            return .toggle
        case let .keyUp(code) where code == swallowKeyUp:
            swallowKeyUp = nil
            return .swallow
        default:
            break
        }

        guard isLocked else { return .pass }

        switch event {
        case .keyDown, .keyUp:
            return active.contains(.keyboard) ? .block : .pass
        case let .systemDefined(subtype):
            return subtype == Self.mediaKeySubtype && active.contains(.keyboard) ? .block : .pass
        case .click, .scroll, .gesture:
            return active.contains(.clicks) ? .block : .pass
        case .pointerMove:
            return active.contains(.pointer) ? .blockAndWarp : .pass
        case .flagsChanged, .other:
            return .pass
        }
    }
}
