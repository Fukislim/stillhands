import AppKit
import StillhandsCore
import SwiftUI

enum DocsRenderer {
    static func run(outputDir: URL) {
        NSApplication.shared.setActivationPolicy(.accessory)
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let state = previewState()
        let items = MenuBar(state: state, actions: MenuBar.Actions()).menu.items

        render(MenuReplica(items: items, appearance: .aqua), .aqua, outputDir, "menu-light.png")
        render(MenuReplica(items: items, appearance: .darkAqua), .darkAqua, outputDir, "menu-dark.png")
        render(DocsFrame { SettingsView(state: state, recorder: ShortcutRecorder(state: state)) }, .aqua, outputDir, "settings-light.png")
        render(DocsFrame { SettingsView(state: state, recorder: ShortcutRecorder(state: state)) }, .darkAqua, outputDir, "settings-dark.png")
        render(HUDBackdrop(), .darkAqua, outputDir, "hud.png")
    }

    private static func previewState() -> AppState {
        let s = AppState(store: nil)
        s.shortcut = Shortcut("J", [.control, .option, .shift])
        s.axTrusted = true
        return s
    }

    private static func render<V: View>(_ view: V, _ appearance: NSAppearance.Name, _ dir: URL, _ name: String) {
        let host = NSHostingView(rootView: view)
        let size = host.fittingSize
        host.frame = CGRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: CGRect(x: -10_000, y: -10_000, width: size.width, height: size.height),
            styleMask: .borderless, backing: .buffered, defer: false
        )
        window.appearance = NSAppearance(named: appearance)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = host
        window.orderFrontRegardless()
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        rep.size = size
        host.cacheDisplay(in: host.bounds, to: rep)
        window.orderOut(nil)

        let url = dir.appendingPathComponent(name)
        try! rep.representation(using: .png, properties: [:])!.write(to: url)
        print("wrote \(url.path)")
    }
}

private struct DocsFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
            .padding(24)
    }
}

private struct MenuReplica: View {
    let items: [NSMenuItem]
    let appearance: NSAppearance.Name

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 14) {
                Image(nsImage: IconStyle.hand.image(locked: false)).renderingMode(.template)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.15)))
                Image(systemName: "wifi")
                Image(systemName: "battery.100percent")
            }
            .font(.system(size: 14))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .windowBackgroundColor)))

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    row(item, highlighted: index == 0)
                }
            }
            .padding(5)
            .frame(minWidth: 250)
            .fixedSize()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
            )
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(nsColor: .separatorColor), lineWidth: 0.5))
        }
        .padding(24)
    }

    @ViewBuilder private func row(_ item: NSMenuItem, highlighted: Bool) -> some View {
        if let view = item.view {
            Image(nsImage: snapshot(view))
        } else if item.isSeparatorItem {
            Divider().padding(.horizontal, 10).padding(.vertical, 5)
        } else if isSectionHeader(item) {
            Text(item.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 3)
                .padding(.bottom, 1)
        } else {
            HStack(spacing: 5) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .opacity(item.state == .on ? 1 : 0)
                    .frame(width: 13)
                Text(item.title).font(.system(size: 13))
                Spacer()
                if item.submenu != nil {
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).opacity(0.6)
                } else if !item.keyEquivalent.isEmpty {
                    Text(keyLabel(item)).font(.system(size: 13)).opacity(highlighted ? 0.85 : 0.5)
                }
            }
            .padding(.horizontal, 6)
            .frame(height: 22)
            .foregroundStyle(highlighted ? Color.white : item.isEnabled ? Color.primary : Color.secondary)
            .background(RoundedRectangle(cornerRadius: 5).fill(highlighted ? Color.accentColor : .clear))
        }
    }

    private func snapshot(_ view: NSView) -> NSImage {
        view.appearance = NSAppearance(named: appearance)
        view.layoutSubtreeIfNeeded()
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        let image = NSImage(size: view.bounds.size)
        image.addRepresentation(rep)
        return image
    }

    private func isSectionHeader(_ item: NSMenuItem) -> Bool {
        if #available(macOS 14, *) { return item.isSectionHeader }
        return false
    }

    private func keyLabel(_ item: NSMenuItem) -> String {
        let m = item.keyEquivalentModifierMask
        var s = ""
        if m.contains(.control) { s += "⌃" }
        if m.contains(.option) { s += "⌥" }
        if m.contains(.shift) { s += "⇧" }
        if m.contains(.command) { s += "⌘" }
        return s + (item.keyEquivalent == " " ? "Space" : item.keyEquivalent.uppercased())
    }
}

private struct HUDBackdrop: View {
    var body: some View {
        HUDView(text: "Input locked", symbol: "lock.fill")
            .frame(width: 360, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12).fill(
                    LinearGradient(colors: [Color(red: 0.16, green: 0.30, blue: 0.45), Color(red: 0.10, green: 0.45, blue: 0.50)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            )
            .padding(24)
    }
}
