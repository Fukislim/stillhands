import AppKit
import Carbon
import Combine
import IOKit.pwr_mgt
import StillhandsCore

final class InputBlocker {
    enum Reason { case shortcut, button, autoUnlock }

    private let state: AppState
    private let hud: HUD
    private let cover: ScreenCover
    private var policy: EventPolicy
    private var tap: CFMachPort?
    private var lockPoint = CGPoint.zero
    private var sleepAssertion: IOPMAssertionID = 0
    private var autoUnlockTimer: Timer?
    private var bag: Set<AnyCancellable> = []

    init(state: AppState, hud: HUD, cover: ScreenCover) {
        self.state = state
        self.hud = hud
        self.cover = cover
        policy = EventPolicy(shortcut: state.shortcut)
        state.$shortcut.sink { [weak self] in self?.policy.shortcut = $0 }.store(in: &bag)
        state.$isRecording.sink { [weak self] in self?.policy.isRecording = $0 }.store(in: &bag)
    }

    private static let eventMask: CGEventMask = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 14, 18, 19, 20, 22, 25, 26, 27, 29, 30, 31, 32, 34]
        .reduce(0) { $0 | (1 << $1) }

    func start() {
        guard tap == nil else { return }
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            let blocker = Unmanaged<InputBlocker>.fromOpaque(userInfo!).takeUnretainedValue()
            return blocker.handle(type: type, event: event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: Self.eventMask, callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            state.tapError = "Couldn't start. Remove Stillhands from Accessibility and add it again."
            return
        }
        self.tap = tap
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        state.tapError = nil
    }

    func stop() {
        if policy.isLocked { setLocked(false, reason: .button) }
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        tap = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        switch policy.decide(Self.kind(of: type, event)) {
        case .pass:
            return Unmanaged.passUnretained(event)
        case .swallow, .block:
            return nil
        case .blockAndWarp:
            CGWarpMouseCursorPosition(lockPoint)
            return nil
        case .toggle:
            setLocked(!policy.isLocked, reason: .shortcut)
            return nil
        }
    }

    private static func kind(of type: CGEventType, _ event: CGEvent) -> StillhandsCore.EventKind {
        switch type.rawValue {
        case 10:
            return .keyDown(
                keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
                flags: event.flags.rawValue,
                autorepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            )
        case 11: return .keyUp(keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)))
        case 12: return .flagsChanged
        case 14: return .systemDefined(subtype: NSEvent(cgEvent: event)?.subtype.rawValue ?? 0)
        case 5, 6, 7, 27: return .pointerMove
        case 1, 2, 3, 4, 25, 26: return .click
        case 22: return .scroll
        case 18, 19, 20, 29, 30, 31, 32, 34: return .gesture
        default: return .other
        }
    }

    func setLocked(_ on: Bool, reason: Reason) {
        guard on != policy.isLocked else { return }
        on ? lock() : unlock(reason: reason)
    }

    private func lock() {
        guard tap != nil else { return }
        let categories = state.activeCategories
        if categories.isEmpty {
            hud.show("Nothing selected to lock", symbol: "exclamationmark.triangle.fill")
            return
        }
        if IsSecureEventInputEnabled() {
            hud.show("Can't lock while a password field is active", symbol: "exclamationmark.triangle.fill")
            return
        }

        policy.active = categories
        policy.isLocked = true

        if categories.contains(.pointer) {
            lockPoint = CGEvent(source: nil)?.location ?? .zero
            CGAssociateMouseAndMouseCursorPosition(0)
        }
        IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Stillhands input lock" as CFString,
            &sleepAssertion
        )
        if state.autoUnlockMinutes > 0 {
            let seconds = TimeInterval(state.autoUnlockMinutes * 60)
            state.autoUnlockAt = Date().addingTimeInterval(seconds)
            autoUnlockTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                self?.setLocked(false, reason: .autoUnlock)
            }
        }
        if state.blackOut { cover.show() }

        state.isLocked = true
        hud.show("Input locked", symbol: "lock.fill")
    }

    private func unlock(reason: Reason) {
        policy.isLocked = false
        policy.active = []

        CGAssociateMouseAndMouseCursorPosition(1)
        if sleepAssertion != 0 {
            IOPMAssertionRelease(sleepAssertion)
            sleepAssertion = 0
        }
        autoUnlockTimer?.invalidate()
        autoUnlockTimer = nil
        state.autoUnlockAt = nil
        cover.hide()

        state.isLocked = false
        hud.show(reason == .autoUnlock ? "Unlocked (safety timer)" : "Unlocked", symbol: "lock.open.fill")
    }
}
