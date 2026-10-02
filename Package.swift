// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Clipboard",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "ClipboardKit", targets: ["ClipboardKit"]),
        .executable(name: "Clipboard", targets: ["Clipboard"]),
        .executable(name: "ClipboardTestRunner", targets: ["ClipboardTestRunner"])
    ],
    targets: [
        .target(
            name: "ClipboardKit",
            dependencies: [],
            path: "Sources/ClipboardKit"
        ),
        .executableTarget(
            name: "Clipboard",
            dependencies: ["ClipboardKit"],
            path: "Sources/Clipboard"
        ),
        .executableTarget(
            name: "ClipboardTestRunner",
            dependencies: ["ClipboardKit"],
            path: "Sources/ClipboardTestRunner"
        )
    ]
)
