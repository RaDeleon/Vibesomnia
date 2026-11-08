// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Vibesomnia",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Vibesomnia", targets: ["Vibesomnia"]),
        .executable(name: "vibesomnia-cli", targets: ["VibesomniaCLI"])
    ],
    targets: [
        .target(name: "VibesomniaCore"),
        .executableTarget(name: "Vibesomnia", dependencies: ["VibesomniaCore"]),
        .executableTarget(name: "VibesomniaCLI", dependencies: ["VibesomniaCore"]),
        .testTarget(name: "VibesomniaCoreTests", dependencies: ["VibesomniaCore"])
    ]
)
