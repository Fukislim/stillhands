import Foundation
import Testing
@testable import StillhandsCore

@Suite struct LockSessionTests {
    struct Case: CustomTestStringConvertible, Sendable {
        let name: String
        var touchID = false
        let events: [LockSession.Event]
        let effects: [LockSession.Effect]
        let phase: LockSession.Phase
        var testDescription: String { name }
    }

    static let cases: [Case] = [
        Case(name: "unlock without Touch ID", events: [.unlockRequested],
             effects: [.unlock(message: "Unlocked")], phase: .unlocked),
        Case(name: "safety timer", events: [.safetyTimer],
             effects: [.unlock(message: "Unlocked (safety timer)")], phase: .unlocked),
        Case(name: "Touch ID verified", touchID: true, events: [.unlockRequested, .touchID(.verified)],
             effects: [.verify, .unlock(message: "Unlocked")], phase: .unlocked),
        Case(name: "repeated request while verifying is ignored", touchID: true,
             events: [.unlockRequested, .unlockRequested],
             effects: [.verify, .none], phase: .verifying),
        Case(name: "failed Touch ID stays locked and can retry", touchID: true,
             events: [.unlockRequested, .touchID(.failed), .unlockRequested],
             effects: [.verify, .stillLocked, .verify], phase: .verifying),
        Case(name: "Touch ID unavailable unlocks", touchID: true, events: [.unlockRequested, .touchID(.unavailable)],
             effects: [.verify, .unlock(message: "Unlocked (Touch ID unavailable)")], phase: .unlocked),
        Case(name: "safety timer while verifying, then stale result", touchID: true,
             events: [.unlockRequested, .safetyTimer, .touchID(.failed)],
             effects: [.verify, .unlock(message: "Unlocked (safety timer)"), .none], phase: .unlocked),
        Case(name: "quit skips Touch ID", touchID: true, events: [.quit],
             effects: [.unlock(message: "Unlocked")], phase: .unlocked),
        Case(name: "Touch ID result without a request is ignored", touchID: true, events: [.touchID(.verified)],
             effects: [.none], phase: .locked),
    ]

    static let start = Date(timeIntervalSince1970: 0)

    @Test(arguments: cases) func transitions(_ c: Case) {
        var session = LockSession()
        session.lock(at: Self.start, requireTouchID: c.touchID)
        #expect(c.events.map { session.handle($0) } == c.effects)
        #expect(session.phase == c.phase)
    }

    @Test func eventsWhileUnlockedDoNothing() {
        var session = LockSession()
        #expect([.unlockRequested, .safetyTimer, .quit, .touchID(.verified)].map { session.handle($0) } == [LockSession.Effect](repeating: .none, count: 4))
        #expect(session.phase == .unlocked)
    }

    @Test(arguments: [
        ([], "Unlocked"),
        ([0, 1], "Unlocked, touched once while locked"),
        ([0, 5, 10], "Unlocked, touched 3× while locked"),
    ] as [([TimeInterval], String)])
    func unlockMessageCountsTouches(offsets: [TimeInterval], message: String) {
        var session = LockSession()
        session.lock(at: Self.start, requireTouchID: false)
        for offset in offsets { _ = session.touch(at: Self.start.addingTimeInterval(offset)) }
        #expect(session.handle(.unlockRequested) == .unlock(message: message))
    }

    @Test func savedPhotosBelongToTheLockTheyWereTakenIn() {
        var session = LockSession()
        session.photoSaved(takenAt: Self.start)
        #expect(session.savedPhotos == 0)

        session.lock(at: Self.start, requireTouchID: false)
        session.photoSaved(takenAt: Self.start.addingTimeInterval(5))
        _ = session.handle(.unlockRequested)
        session.photoSaved(takenAt: Self.start.addingTimeInterval(10))
        #expect(session.savedPhotos == 2)

        session.lock(at: Self.start.addingTimeInterval(60), requireTouchID: false)
        session.photoSaved(takenAt: Self.start.addingTimeInterval(10))
        #expect(session.savedPhotos == 0)
    }
}
