import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var state: AppState!
    private var blocker: InputBlocker!
    private var settings: SettingsWindow!
    private var menuBar: MenuBar!
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState(store: .standard)
        blocker = InputBlocker(state: state, hud: HUD(), cover: ScreenCover())
        settings = SettingsWindow(state: state)
        menuBar = MenuBar(state: state, actions: MenuBar.Actions(
            lock: { [blocker] in blocker?.setLocked(true, reason: .button) },
            unlock: { [blocker] in blocker?.setLocked(false, reason: .button) },
            openSettings: { [settings] in settings?.show() }
        ))
        menuBar.install()

        if AXIsProcessTrusted() {
            state.axTrusted = true
            blocker.start()
        } else {
            let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard AXIsProcessTrusted(), let self else { return }
                timer.invalidate()
                state.axTrusted = true
                blocker.start()
            }
        }

        if !state.didOnboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.settings.show()
                self?.state.didOnboard = true
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        blocker?.stop()
    }
}
