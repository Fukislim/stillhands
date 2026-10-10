import Foundation

public struct LockSession: Sendable {
    public enum Phase: Equatable, Sendable { case unlocked, locked, verifying }
    public enum Verification: Equatable, Sendable { case verified, unavailable, failed }
    public enum Event: Equatable, Sendable { case unlockRequested, safetyTimer, quit, touchID(Verification) }
    public enum Effect: Equatable, Sendable { case none, verify, stillLocked, unlock(message: String) }

    public private(set) var phase = Phase.unlocked
    public private(set) var savedPhotos = 0
    private var requireTouchID = false
    private var lockedAt: Date?
    private var touchLog = TouchLog()

    public init() {}

    public mutating func lock(at now: Date, requireTouchID: Bool) {
        phase = .locked
        self.requireTouchID = requireTouchID
        lockedAt = now
        touchLog = TouchLog()
        savedPhotos = 0
    }

    public mutating func touch(at now: Date) -> Bool {
        touchLog.touch(at: now)
    }

    public mutating func photoSaved(takenAt: Date) {
        guard let lockedAt, takenAt >= lockedAt else { return }
        savedPhotos += 1
    }

    public mutating func handle(_ event: Event) -> Effect {
        switch (phase, event) {
        case (.unlocked, _), (.locked, .touchID), (.verifying, .unlockRequested):
            return .none
        case (.locked, .unlockRequested) where requireTouchID:
            phase = .verifying
            return .verify
        case (.verifying, .touchID(.failed)):
            phase = .locked
            return .stillLocked
        case (_, .touchID(.unavailable)):
            return unlock("Unlocked (Touch ID unavailable)")
        case (_, .safetyTimer):
            return unlock("Unlocked (safety timer)")
        case (_, .unlockRequested), (_, .quit), (_, .touchID(.verified)):
            return unlock("Unlocked")
        }
    }

    private mutating func unlock(_ message: String) -> Effect {
        phase = .unlocked
        return .unlock(message: message + touchSummary)
    }

    private var touchSummary: String {
        switch touchLog.touches {
        case 0: ""
        case 1: ", touched once while locked"
        default: ", touched \(touchLog.touches)× while locked"
        }
    }
}
