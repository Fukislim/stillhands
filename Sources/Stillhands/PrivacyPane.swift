import AppKit

enum PrivacyPane: String {
    case accessibility = "Privacy_Accessibility"
    case camera = "Privacy_Camera"

    func open() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?\(rawValue)")!)
    }
}
