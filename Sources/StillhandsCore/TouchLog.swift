import Foundation

public struct TouchLog: Equatable, Sendable {
    public static let burstGap: TimeInterval = 2
    public static let photoInterval: TimeInterval = 30
    public static let maxPhotos = 20

    public private(set) var touches = 0
    public private(set) var photos = 0
    private var lastTouch: Date?
    private var lastPhoto: Date?

    public init() {}

    public mutating func touch(at now: Date) -> Bool {
        if lastTouch.map({ now.timeIntervalSince($0) >= Self.burstGap }) ?? true { touches += 1 }
        lastTouch = now
        guard photos < Self.maxPhotos, lastPhoto.map({ now.timeIntervalSince($0) >= Self.photoInterval }) ?? true else {
            return false
        }
        photos += 1
        lastPhoto = now
        return true
    }
}
