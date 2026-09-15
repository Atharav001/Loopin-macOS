// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Loopin",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Loopin", targets: ["Loopin"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Loopin",
            dependencies: [],
            path: "Sources/Loopin"
        ),
        .testTarget(
            name: "LoopinTests",
            dependencies: ["Loopin"],
            path: "Tests/LoopinTests"
        )
    ]
)
