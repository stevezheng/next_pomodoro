// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PomodoroTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PomodoroTimer",
            targets: ["PomodoroTimer"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "PomodoroTimer",
            dependencies: [],
            path: "Sources/PomodoroTimer"
        )
    ]
)
