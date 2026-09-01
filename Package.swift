// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ToolVN",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ToolVNCore", targets: ["ToolVNCore"]),
        .library(name: "ToolVNTestFixtures", targets: ["ToolVNTestFixtures"]),
        .executable(name: "toolvn-verify", targets: ["toolvn-verify"]),
        .executable(name: "toolvn-test", targets: ["toolvn-test"]),
    ],
    targets: [
        .target(name: "ToolVNCore", path: "Sources/ToolVNCore"),
        .target(
            name: "ToolVNTestFixtures",
            dependencies: ["ToolVNCore"],
            path: "Sources/ToolVNTestFixtures"
        ),
        .executableTarget(
            name: "toolvn-verify",
            dependencies: ["ToolVNCore"],
            path: "Sources/toolvn-verify"
        ),
        .executableTarget(
            name: "toolvn-test",
            dependencies: ["ToolVNTestFixtures"],
            path: "Sources/toolvn-test"
        ),
        .testTarget(
            name: "ToolVNCoreTests",
            dependencies: ["ToolVNCore", "ToolVNTestFixtures"],
            path: "Tests/ToolVNCoreTests"
        ),
    ]
)
