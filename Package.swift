// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Vibesomnia",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Vibesomnia", targets: ["Vibesomnia"]),
        .executable(name: "vibesomnia-cli", targets: ["VibesomniaCLI"]),
        .executable(name: "VibesomniaPowerGuard", targets: ["VibesomniaPowerGuard"])
    ],
    targets: [
        .target(name: "VibesomniaCore", dependencies: ["VibeSystem"]),
        .target(name: "VibeSystem", publicHeadersPath: "include"),
        .executableTarget(name: "VibesomniaPowerGuard", dependencies: ["VibesomniaCore", "VibeSystem"]),
        .executableTarget(name: "Vibesomnia", dependencies: ["VibesomniaCore", "VibeSystem"]),
        .executableTarget(name: "VibesomniaCLI", dependencies: ["VibesomniaCore"]),
        .testTarget(name: "VibesomniaCoreTests", dependencies: ["VibesomniaCore"])
    ]
)
