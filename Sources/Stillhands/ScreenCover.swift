import AppKit

final class ScreenCover {
    private var windows: [NSWindow] = []
    private var observer: NSObjectProtocol?

    func show() {
        buildWindows(fadeIn: true)
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.closeWindows()
            self?.buildWindows(fadeIn: false)
        }
    }

    func hide() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        let closing = windows
        windows = []
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            closing.forEach { $0.animator().alphaValue = 0 }
        }, completionHandler: {
            closing.forEach { $0.orderOut(nil) }
        })
    }

    private func buildWindows(fadeIn: Bool) {
        windows = NSScreen.screens.map { screen in
            let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.setFrame(screen.frame, display: false)
            w.backgroundColor = .black
            w.level = .screenSaver
            w.ignoresMouseEvents = true
            w.isReleasedWhenClosed = false
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            w.alphaValue = fadeIn ? 0 : 1
            w.orderFrontRegardless()
            return w
        }
        guard fadeIn else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            windows.forEach { $0.animator().alphaValue = 1 }
        }
    }

    private func closeWindows() {
        windows.forEach { $0.orderOut(nil) }
        windows = []
    }
}
