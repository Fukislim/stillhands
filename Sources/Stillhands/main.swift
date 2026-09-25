import AppKit

let args = CommandLine.arguments
if let i = args.firstIndex(of: "--render-docs") {
    let dir = args.indices.contains(i + 1) ? args[i + 1] : "docs/images"
    DocsRenderer.run(outputDir: URL(fileURLWithPath: dir))
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
