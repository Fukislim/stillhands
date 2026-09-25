import AppKit

enum Glyphs {
    static func draw(_ style: IconStyle, locked: Bool) {
        NSColor.black.set()
        switch style {
        case .alien: alien(locked)
        case .genie: genie(locked)
        case .horus: horus(locked)
        case .cat: cat(locked)
        default: break
        }
    }

    private static func alien(_ locked: Bool) {
        let head = NSBezierPath()
        head.move(to: p(50, 6))
        head.curve(to: p(8, 60), controlPoint1: p(22, 10), controlPoint2: p(6, 36))
        head.curve(to: p(50, 96), controlPoint1: p(10, 86), controlPoint2: p(30, 96))
        head.curve(to: p(92, 60), controlPoint1: p(70, 96), controlPoint2: p(90, 86))
        head.curve(to: p(50, 6), controlPoint1: p(94, 36), controlPoint2: p(78, 10))
        head.close()
        let eyes = [almond(p(31, 50), -28), almond(p(69, 50), 28)]
        if locked {
            head.fill()
            eyes.forEach(cut)
        } else {
            stroke(head)
            eyes.forEach { $0.fill() }
        }
    }

    private static func genie(_ locked: Bool) {
        let body = NSBezierPath()
        body.move(to: p(20, 44))
        body.curve(to: p(50, 20), controlPoint1: p(20, 28), controlPoint2: p(34, 20))
        body.curve(to: p(74, 34), controlPoint1: p(62, 20), controlPoint2: p(70, 26))
        body.curve(to: p(97, 50), controlPoint1: p(84, 36), controlPoint2: p(90, 46))
        body.curve(to: p(76, 44), controlPoint1: p(90, 48), controlPoint2: p(82, 44))
        body.close()
        let lid = NSBezierPath(ovalIn: NSRect(x: 40, y: 46, width: 20, height: 10))
        let foot = NSBezierPath(roundedRect: NSRect(x: 36, y: 6, width: 28, height: 9), xRadius: 3, yRadius: 3)
        let handle = NSBezierPath()
        handle.appendArc(withCenter: p(18, 34), radius: 11, startAngle: 70, endAngle: 290)
        stroke(handle)
        foot.fill()
        if locked {
            body.fill()
            lid.fill()
        } else {
            stroke(body)
            stroke(lid)
            let smoke = NSBezierPath()
            smoke.move(to: p(94, 58))
            smoke.curve(to: p(76, 78), controlPoint1: p(102, 68), controlPoint2: p(78, 68))
            smoke.curve(to: p(88, 96), controlPoint1: p(74, 88), controlPoint2: p(90, 88))
            stroke(smoke)
        }
    }

    private static func horus(_ locked: Bool) {
        let brow = NSBezierPath()
        brow.move(to: p(8, 80))
        brow.curve(to: p(94, 78), controlPoint1: p(36, 94), controlPoint2: p(70, 94))
        let eye = NSBezierPath()
        eye.move(to: p(10, 58))
        eye.curve(to: p(88, 58), controlPoint1: p(34, 76), controlPoint2: p(64, 76))
        eye.curve(to: p(10, 58), controlPoint1: p(64, 42), controlPoint2: p(34, 42))
        eye.close()
        let marks = NSBezierPath()
        marks.move(to: p(88, 58))
        marks.line(to: p(98, 58))
        marks.move(to: p(40, 46))
        marks.line(to: p(34, 8))
        marks.move(to: p(58, 45))
        marks.curve(to: p(80, 18), controlPoint1: p(70, 38), controlPoint2: p(84, 30))
        marks.curve(to: p(64, 16), controlPoint1: p(76, 6), controlPoint2: p(62, 8))
        stroke(brow)
        stroke(marks)
        if locked {
            let lid = NSBezierPath()
            lid.move(to: p(10, 60))
            lid.curve(to: p(88, 58), controlPoint1: p(34, 44), controlPoint2: p(64, 44))
            lid.lineWidth = 11
            lid.lineCapStyle = .round
            lid.stroke()
        } else {
            stroke(eye)
            NSBezierPath(ovalIn: NSRect(x: 40, y: 50, width: 17, height: 17)).fill()
        }
    }

    private static func cat(_ locked: Bool) {
        let head = NSBezierPath(ovalIn: NSRect(x: 10, y: 8, width: 80, height: 70))
        let ears = NSBezierPath()
        ears.move(to: p(16, 60))
        ears.line(to: p(20, 96))
        ears.line(to: p(42, 76))
        ears.move(to: p(84, 60))
        ears.line(to: p(80, 96))
        ears.line(to: p(58, 76))
        let nose = NSBezierPath()
        nose.move(to: p(44, 34))
        nose.line(to: p(56, 34))
        nose.line(to: p(50, 27))
        nose.close()
        if locked {
            head.fill()
            ears.close()
            ears.fill()
            stroke(ears)
            cut(NSBezierPath(roundedRect: NSRect(x: 24, y: 42, width: 18, height: 5), xRadius: 2.5, yRadius: 2.5))
            cut(NSBezierPath(roundedRect: NSRect(x: 58, y: 42, width: 18, height: 5), xRadius: 2.5, yRadius: 2.5))
            cut(nose)
        } else {
            stroke(head)
            stroke(ears)
            NSBezierPath(ovalIn: NSRect(x: 28, y: 38, width: 10, height: 14)).fill()
            NSBezierPath(ovalIn: NSRect(x: 62, y: 38, width: 10, height: 14)).fill()
            nose.fill()
        }
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x, y: y) }

    private static func almond(_ center: NSPoint, _ angle: CGFloat) -> NSBezierPath {
        let path = NSBezierPath(ovalIn: NSRect(x: -14, y: -8, width: 28, height: 16))
        var transform = AffineTransform(translationByX: center.x, byY: center.y)
        transform.rotate(byDegrees: angle)
        path.transform(using: transform)
        return path
    }

    private static func stroke(_ path: NSBezierPath) {
        path.lineWidth = 8
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }

    private static func cut(_ path: NSBezierPath) {
        NSGraphicsContext.current?.compositingOperation = .destinationOut
        path.fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver
    }
}
