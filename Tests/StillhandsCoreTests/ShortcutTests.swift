import Foundation
import Testing
@testable import StillhandsCore

@Suite struct ShortcutTests {
    let ctrlOptShiftJ = Shortcut(keyCode: 38, modifiers: [.control, .option, .shift])

    @Test func displayUsesAppleOrder() {
        #expect(ctrlOptShiftJ.display == "⌃⌥⇧J")
        #expect(Shortcut("K", [.command, .shift, .control]).display == "⌃⇧⌘K")
        #expect(ctrlOptShiftJ.keycaps == ["⌃", "⌥", "⇧", "J"])
    }

    @Test func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(ctrlOptShiftJ)
        #expect(try JSONDecoder().decode(Shortcut.self, from: data) == ctrlOptShiftJ)
    }

    @Test func matchesExactModifiersOnly() {
        let flags = Modifiers([.control, .option, .shift]).cgFlags
        let capsLock: UInt64 = 0x10000, fn: UInt64 = 0x800000, deviceBits: UInt64 = 0x101
        #expect(ctrlOptShiftJ.matches(keyCode: 38, cgFlags: flags))
        #expect(ctrlOptShiftJ.matches(keyCode: 38, cgFlags: flags | capsLock | fn | deviceBits))
        #expect(!ctrlOptShiftJ.matches(keyCode: 38, cgFlags: Modifiers([.control, .option]).cgFlags))
        #expect(!ctrlOptShiftJ.matches(keyCode: 38, cgFlags: flags | Modifiers.command.cgFlags))
        #expect(!ctrlOptShiftJ.matches(keyCode: 40, cgFlags: flags))
    }

    @Test func randomIsAlwaysValidThreeModifierCombo() {
        for _ in 0..<1000 {
            let s = Shortcut.random()
            #expect(s.modifiers.count == 3)
            #expect(KeyNames.randomPool.contains(s.keyCode))
            #expect(s.validate() == nil)
        }
    }

    @Test func randomPoolIsLettersAndDigits() {
        #expect(KeyNames.randomPool.count == 36)
    }

    @Test func validation() {
        #expect(Shortcut("J", [.command]).validate() == .tooFewModifiers)
        #expect(Shortcut("4", [.shift, .command]).validate() == .reserved)
        #expect(Shortcut("⎋", [.control, .option]).validate() == .unsupportedKey)
        #expect(Shortcut(keyCode: 0x3F, modifiers: [.control, .option]).validate() == .unsupportedKey)
        #expect(ctrlOptShiftJ.validate() == nil)
    }
}
