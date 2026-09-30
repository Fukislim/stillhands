import Foundation

public struct PhotoArchive: Sendable {
    public static let keepMonths = 3

    public let calendar: Calendar

    public init(calendar: Calendar = .current) { self.calendar = calendar }

    public func folderName(for date: Date) -> String { formatter("yyyy-MM-dd").string(from: date) }

    public func fileName(for date: Date) -> String { formatter("HH-mm-ss").string(from: date) + ".jpg" }

    public func expired(_ folders: [String], now: Date) -> [String] {
        guard let cutoff = calendar.date(byAdding: .month, value: -Self.keepMonths, to: calendar.startOfDay(for: now)) else {
            return []
        }
        let days = formatter("yyyy-MM-dd")
        return folders.filter { name in
            guard let day = days.date(from: name), days.string(from: day) == name else { return false }
            return day < cutoff
        }
    }

    private func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = format
        return f
    }
}
