import AppKit
import StillhandsCore

final class ShortcutRecorder: ObservableObject {
    @Published private(set) var hint: String?
    private let state: AppState
    private var monitor: Any?

    init(state: AppState) { self.state = state }

    func start() {
        hint = nil
        state.isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return nil
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        state.isRecording = false
    }

    private func handle(_ event: NSEvent) {
        if event.keyCode == KeyNames.escape { return stop() }
        let candidate = Shortcut(keyCode: event.keyCode, modifiers: Modifiers(cgFlags: UInt64(event.modifierFlags.rawValue)))
        switch candidate.validate() {
        case nil:
            state.shortcut = candidate
            stop()
        case .tooFewModifiers: show("Use at least two modifier keys")
        case .reserved: show("Reserved by macOS, pick another")
        case .unsupportedKey: show("Key not supported")
        }
    }

    private func show(_ text: String) {
        hint = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.hint == text { self?.hint = nil }
        }
    }
}
