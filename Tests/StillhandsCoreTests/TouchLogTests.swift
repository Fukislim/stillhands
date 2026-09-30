import Foundation
import Testing
@testable import StillhandsCore

@Suite struct TouchLogTests {
    struct Case: CustomTestStringConvertible, Sendable {
        let name: String
        let offsets: [TimeInterval]
        let photos: [Bool]
        let touches: Int
        var testDescription: String { name }
    }

    static let cases: [Case] = [
        Case(name: "first touch takes a photo", offsets: [0], photos: [true], touches: 1),
        Case(name: "one burst takes one photo", offsets: [0, 0.5, 1, 1.5], photos: [true, false, false, false], touches: 1),
        Case(name: "a pause starts a new touch", offsets: [0, 2, 5], photos: [true, false, false], touches: 3),
        Case(name: "next photo after the interval", offsets: [0, 29.9, 30], photos: [true, false, true], touches: 2),
    ]

    @Test(arguments: cases) func touches(_ c: Case) {
        var log = TouchLog()
        let start = Date(timeIntervalSince1970: 0)
        #expect(c.offsets.map { log.touch(at: start.addingTimeInterval($0)) } == c.photos)
        #expect(log.touches == c.touches)
        #expect(log.photos == c.photos.filter { $0 }.count)
    }

    @Test func photosAreCapped() {
        var log = TouchLog()
        let shots = (0..<TouchLog.maxPhotos + 5).map { log.touch(at: Date(timeIntervalSince1970: Double($0) * TouchLog.photoInterval)) }
        #expect(shots.filter { $0 }.count == TouchLog.maxPhotos)
        #expect(shots.suffix(5) == Array(repeating: false, count: 5))
        #expect(log.touches == TouchLog.maxPhotos + 5)
    }
}
