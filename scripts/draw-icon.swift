import AppKit

let assets = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "assets")

func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: a)
}

let handSVG = try! String(contentsOf: assets.appendingPathComponent("palm-down-hand.svg"), encoding: .utf8)
    .replacingOccurrences(of: "#FFDC5D", with: "#FFFFFF")
    .replacingOccurrences(of: "#EF9645", with: "#D4C4FF")
let hand = NSImage(data: handSVG.data(using: .utf8)!)!

func drawIcon() {
    let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    let colors = [hex(0x7C3AED), hex(0x4C1D95)]

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current!.cgContext.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: hex(0, 0.3).cgColor)
    colors[0].setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSGradient(colors: colors)!.draw(in: tile, angle: -90)
    tile.addClip()
    let shadow = NSBezierPath(ovalIn: NSRect(x: 260, y: 262, width: 500, height: 90))
    NSGradient(colors: [hex(0x2E1065, 0.45), hex(0x2E1065, 0)])!.draw(in: shadow, relativeCenterPosition: .zero)
    let flip = NSAffineTransform()
    flip.translateX(by: 1260, yBy: 0)
    flip.scaleX(by: -1, yBy: 1)
    flip.concat()
    hand.draw(in: NSRect(x: 300, y: 300, width: 660, height: 660))
    NSGraphicsContext.restoreGraphicsState()
}

func drawBanner(text: NSColor, tagline: NSColor) {
    let icon = NSImage(size: NSSize(width: 1024, height: 1024), flipped: false) { _ in drawIcon(); return true }
    icon.draw(in: NSRect(x: 40, y: 40, width: 400, height: 400))

    let rounded = NSFont.systemFont(ofSize: 150, weight: .bold).fontDescriptor.withDesign(.rounded)!
    let title = NSAttributedString(string: "Stillhands", attributes: [
        .font: NSFont(descriptor: rounded, size: 150)!,
        .foregroundColor: text,
        .kern: -2,
    ])
    title.draw(at: NSPoint(x: 450, y: 210))
    let sub = NSAttributedString(string: "Lock your keyboard, trackpad and mouse.\nYour screen stays on.", attributes: [
        .font: NSFont.systemFont(ofSize: 40, weight: .medium),
        .foregroundColor: tagline,
    ])
    sub.draw(at: NSPoint(x: 458, y: 90))
}

func write(_ size: NSSize, scale: CGFloat, _ name: String, _ draw: () -> Void) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: assets.appendingPathComponent(name))
    print("wrote \(assets.appendingPathComponent(name).path)")
}

write(NSSize(width: 1024, height: 1024), scale: 1, "logo.png", drawIcon)
write(NSSize(width: 1400, height: 480), scale: 2, "banner-light.png") { drawBanner(text: hex(0x1E1036), tagline: hex(0x5B4B7A)) }
write(NSSize(width: 1400, height: 480), scale: 2, "banner-dark.png") { drawBanner(text: .white, tagline: hex(0xC4B5FD)) }
