import AppKit

enum IconStyle: String, CaseIterable {
    case hand, spreadHand, padlock, eye
    case alien, genie, cat, horus

    static let rows: [[IconStyle]] = [[.hand, .spreadHand, .padlock, .eye], [.alien, .genie, .cat, .horus]]

    var title: String {
        switch self {
        case .hand: "Hand"
        case .spreadHand: "Spread Hand"
        case .padlock: "Padlock"
        case .eye: "Eye"
        case .alien: "Alien"
        case .genie: "Genie Lamp"
        case .horus: "Eye of Horus"
        case .cat: "Cat"
        }
    }

    private var symbols: (unlocked: String, locked: String)? {
        switch self {
        case .hand: ("hand.raised", "hand.raised.slash.fill")
        case .spreadHand: ("hand.raised.fingers.spread", "hand.raised.fingers.spread.fill")
        case .padlock: ("lock.open", "lock.fill")
        case .eye: ("eye", "eye.slash.fill")
        default: nil
        }
    }

    func image(locked: Bool, dimmed: Bool = false, size: CGFloat = 15) -> NSImage {
        let glyph: NSImage
        if let symbols {
            glyph = NSImage(systemSymbolName: locked ? symbols.locked : symbols.unlocked, accessibilityDescription: nil)!
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: size, weight: .regular))!
        } else {
            let side = size + 2
            glyph = NSImage(size: NSSize(width: side, height: side), flipped: false) { _ in
                let transform = NSAffineTransform()
                transform.scale(by: side / 100)
                transform.concat()
                Glyphs.draw(self, locked: locked)
                return true
            }
        }
        let image = NSImage(size: glyph.size, flipped: false) { rect in
            glyph.draw(in: rect, from: .zero, operation: .sourceOver, fraction: dimmed ? 0.4 : 1)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Stillhands"
        return image
    }

    var preview: NSImage {
        let unlocked = image(locked: false, size: 12)
        let locked = image(locked: true, size: 12)
        let gap: CGFloat = 3
        let size = NSSize(width: unlocked.size.width + gap + locked.size.width, height: max(unlocked.size.height, locked.size.height))
        let preview = NSImage(size: size, flipped: false) { _ in
            unlocked.draw(at: NSPoint(x: 0, y: (size.height - unlocked.size.height) / 2), from: .zero, operation: .sourceOver, fraction: 1)
            locked.draw(at: NSPoint(x: unlocked.size.width + gap, y: (size.height - locked.size.height) / 2), from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
        preview.isTemplate = true
        preview.accessibilityDescription = title
        return preview
    }
}

