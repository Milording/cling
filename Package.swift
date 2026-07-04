// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cling",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Cling",
            path: "Sources/Cling",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ClingTests",
            dependencies: ["Cling"],
            path: "Tests/ClingTests"
        ),
    ]
)
