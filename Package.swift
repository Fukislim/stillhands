// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Stillhands",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "StillhandsCore"),
        .executableTarget(name: "Stillhands", dependencies: ["StillhandsCore"]),
        .testTarget(name: "StillhandsCoreTests", dependencies: ["StillhandsCore"]),
    ],
    swiftLanguageModes: [.v5]
)
