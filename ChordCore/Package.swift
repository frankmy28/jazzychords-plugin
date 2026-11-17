// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChordCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ChordCore", targets: ["ChordCore"]),
    ],
    targets: [
        .target(name: "ChordCore"),
        .testTarget(name: "ChordCoreTests", dependencies: ["ChordCore"]),
    ]
)
