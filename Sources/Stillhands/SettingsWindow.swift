import AppKit
import SwiftUI

final class SettingsWindow: NSObject, NSWindowDelegate {
    private let state: AppState
    private let recorder: ShortcutRecorder
    private var window: NSWindow?

    init(state: AppState) {
        self.state = state
        recorder = ShortcutRecorder(state: state)
    }

    func show() {
        if window == nil {
            let host = NSHostingController(rootView: SettingsView(
                state: state, recorder: recorder, openAccessibility: Self.openAccessibilitySettings
            ))
            let w = NSWindow(contentViewController: host)
            w.title = "Stillhands Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            window = w
        }
        state.launchAtLogin = LoginItem.isEnabled
        if #available(macOS 14, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        recorder.stop()
    }

    static func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
