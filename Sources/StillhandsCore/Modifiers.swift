public struct Modifiers: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let control = Modifiers(rawValue: 1)
    public static let option = Modifiers(rawValue: 2)
    public static let shift = Modifiers(rawValue: 4)
    public static let command = Modifiers(rawValue: 8)

    private static let table: [(modifier: Modifiers, flag: UInt64, symbol: String)] = [
        (.control, 0x40000, "⌃"),
        (.option, 0x80000, "⌥"),
        (.shift, 0x20000, "⇧"),
        (.command, 0x100000, "⌘"),
    ]

    public init(cgFlags: UInt64) {
        self.init(Self.table.filter { cgFlags & $0.flag != 0 }.map(\.modifier))
    }

    public var cgFlags: UInt64 {
        Self.table.filter { contains($0.modifier) }.reduce(0) { $0 | $1.flag }
    }

    public var symbols: [String] {
        Self.table.filter { contains($0.modifier) }.map(\.symbol)
    }

    public var count: Int { rawValue.nonzeroBitCount }
}
