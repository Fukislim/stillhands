import Foundation
import Testing
@testable import StillhandsCore

@Suite struct PhotoArchiveTests {
    static let archive: PhotoArchive = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        return PhotoArchive(calendar: calendar)
    }()

    static func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: s)!
    }

    @Test func namesUseLocalDayAndTime() {
        let d = Self.date("2026-09-30T22:46:07Z")
        #expect(Self.archive.folderName(for: d) == "2026-10-01")
        #expect(Self.archive.fileName(for: d) == "00-46-07.jpg")
    }

    @Test(arguments: [
        ("2026-06-29", true),
        ("2025-12-31", true),
        ("2026-06-30", false),
        ("2026-09-30", false),
        ("2026-6-1", false),
        ("2026-02-30", false),
        ("Notes", false),
        (".DS_Store", false),
    ])
    func expiresAfterThreeMonths(folder: String, expired: Bool) {
        let now = Self.date("2026-09-30T12:00:00Z")
        #expect(Self.archive.expired([folder], now: now) == (expired ? [folder] : []))
    }
}
