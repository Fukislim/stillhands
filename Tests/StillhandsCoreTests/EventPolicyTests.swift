import Testing
@testable import StillhandsCore

@Suite struct EventPolicyTests {
    static let shortcut = Shortcut("J", [.control, .option, .shift])
    static let shortcutDown = EventKind.keyDown(keyCode: shortcut.keyCode, flags: shortcut.modifiers.cgFlags, autorepeat: false)
    static let plainKeyDown = EventKind.keyDown(keyCode: 0x00, flags: 0, autorepeat: false)

    func locked(_ categories: Set<InputCategory>) -> EventPolicy {
        var p = EventPolicy(shortcut: Self.shortcut)
        p.isLocked = true
        p.active = categories
        return p
    }

    @Test func unlockedPassesEverything() {
        var p = EventPolicy(shortcut: Self.shortcut)
        for e: EventKind in [Self.plainKeyDown, .keyUp(keyCode: 0), .click, .scroll, .gesture, .pointerMove, .systemDefined(subtype: 8)] {
            #expect(p.decide(e) == .pass)
        }
    }

    @Test func shortcutTogglesAndEatsItsKeyUp() {
        var p = EventPolicy(shortcut: Self.shortcut)
        #expect(p.decide(Self.shortcutDown) == .toggle)
        #expect(p.decide(.keyUp(keyCode: Self.shortcut.keyCode)) == .swallow)
        #expect(p.decide(.keyUp(keyCode: Self.shortcut.keyCode)) == .pass)
    }

    @Test func shortcutAutorepeatIsSwallowed() {
        var p = EventPolicy(shortcut: Self.shortcut)
        let repeatDown = EventKind.keyDown(keyCode: Self.shortcut.keyCode, flags: Self.shortcut.modifiers.cgFlags, autorepeat: true)
        #expect(p.decide(repeatDown) == .swallow)
    }

    @Test func shortcutStillWorksWhileKeyboardLocked() {
        var p = locked([.keyboard])
        #expect(p.decide(Self.shortcutDown) == .toggle)
    }

    @Test func keyboardLock() {
        var p = locked([.keyboard])
        #expect(p.decide(Self.plainKeyDown) == .block)
        #expect(p.decide(.keyUp(keyCode: 0)) == .block)
        #expect(p.decide(.flagsChanged) == .pass)
        #expect(p.decide(.systemDefined(subtype: 8)) == .block)
        #expect(p.decide(.systemDefined(subtype: 7)) == .pass)
        #expect(p.decide(.click) == .pass)
        #expect(p.decide(.pointerMove) == .pass)
    }

    @Test func withoutKeyboardCategoryKeysPass() {
        var p = locked([.clicks, .pointer])
        #expect(p.decide(Self.plainKeyDown) == .pass)
        #expect(p.decide(.systemDefined(subtype: 8)) == .pass)
    }

    @Test func clicksLock() {
        var p = locked([.clicks])
        #expect(p.decide(.click) == .block)
        #expect(p.decide(.scroll) == .block)
        #expect(p.decide(.gesture) == .block)
        #expect(p.decide(.pointerMove) == .pass)
    }

    @Test func pointerLock() {
        var p = locked([.pointer])
        #expect(p.decide(.pointerMove) == .blockAndWarp)
        #expect(p.decide(.click) == .pass)
    }

    @Test func recordingLetsShortcutThrough() {
        var p = EventPolicy(shortcut: Self.shortcut)
        p.isRecording = true
        #expect(p.decide(Self.shortcutDown) == .pass)
    }
}
