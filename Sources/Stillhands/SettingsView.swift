import AppKit
import StillhandsCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState
    @ObservedObject var recorder: ShortcutRecorder
    var openAccessibility: () -> Void = {}

    private static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    private static let repo = URL(string: "https://github.com/fukislim/stillhands")!

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if !state.axTrusted || state.tapError != nil { permissionCard }
            lockSection
            shortcutSection
            safetySection
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 320)
        .onDisappear(perform: recorder.stop)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 28, height: 28)
            Text("Stillhands").font(.headline)
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(state.isLocked ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)
                Text(state.isLocked ? "Locked" : "Unlocked")
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.primary.opacity(0.07)))
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.tapError ?? "Stillhands needs Accessibility access to block input. Nothing leaves your Mac.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open System Settings", action: openAccessibility)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.yellow.opacity(0.18)))
    }

    private var lockSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle("Lock")
            SwitchRow("Keyboard", symbol: "keyboard", isOn: $state.lockKeyboard)
            SwitchRow("Clicks & scrolling", symbol: "cursorarrow.click.2", isOn: $state.lockClicks)
            SwitchRow("Pointer movement", symbol: "cursorarrow.motionlines", isOn: $state.lockPointer)
            Divider().padding(.vertical, 2)
            SwitchRow("Black out screens", symbol: "rectangle.inset.filled", isOn: $state.blackOut)
        }
        .disabled(state.isLocked)
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle("Shortcut")
            HStack(spacing: 4) {
                if state.isRecording {
                    Text("Press new shortcut… (esc to cancel)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(state.shortcut.keycaps.enumerated()), id: \.offset) { Keycap($0.element) }
                }
                Spacer()
                Button(state.isRecording ? "Cancel" : "Record") {
                    state.isRecording ? recorder.stop() : recorder.start()
                }
                Button {
                    state.shortcut = .random()
                } label: {
                    Image(systemName: "die.face.5")
                }
                .help("Random shortcut")
                .disabled(state.isRecording)
            }
            .buttonStyle(.bordered)
            .disabled(state.isLocked)

            Text(recorder.hint ?? "Never shown while locked.")
                .font(.caption)
                .foregroundStyle(recorder.hint == nil ? Color.secondary : Color.red)
        }
    }

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle("Safety")
            HStack {
                RowLabel("Auto-unlock after", symbol: "timer")
                Spacer()
                Picker("", selection: $state.autoUnlockMinutes) {
                    ForEach(AppState.autoUnlockOptions, id: \.self) { m in
                        Text(m == 0 ? "Off" : "\(m) min").tag(m)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
                .disabled(state.isLocked)
            }
            SwitchRow("Open at login", symbol: "power", isOn: Binding(
                get: { state.launchAtLogin },
                set: { on in
                    do { try LoginItem.set(on); state.loginError = nil } catch { state.loginError = error.localizedDescription }
                    state.launchAtLogin = LoginItem.isEnabled
                }
            ))
            if let loginError = state.loginError {
                Text(loginError).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("v\(Self.version)")
            Link("GitHub", destination: Self.repo)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

private struct SwitchRow: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    init(_ title: String, symbol: String, isOn: Binding<Bool>) {
        self.title = title
        self.symbol = symbol
        _isOn = isOn
    }

    var body: some View {
        HStack {
            RowLabel(title, symbol: symbol)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(AccentSwitchStyle())
        }
    }
}

private struct RowLabel: View {
    let title: String
    let symbol: String

    init(_ title: String, symbol: String) {
        self.title = title
        self.symbol = symbol
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title)
        }
    }
}

private struct AccentSwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(configuration.isOn ? Color.accentColor : Color.primary.opacity(0.14))
            .frame(width: 32, height: 19)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                    .padding(2)
            }
            .animation(.easeOut(duration: 0.15), value: configuration.isOn)
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(Capsule())
            .onTapGesture { configuration.isOn.toggle() }
    }
}

struct Keycap: View {
    let label: String
    init(_ label: String) { self.label = label }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .frame(minWidth: 22, minHeight: 22)
            .padding(.horizontal, label.count > 1 ? 4 : 0)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(nsColor: .separatorColor)))
    }
}
