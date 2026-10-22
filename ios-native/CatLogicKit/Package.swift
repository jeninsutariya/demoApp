// swift-tools-version: 5.9
import PackageDescription

// Everything in the app that isn't drawing: puzzle engine, game rules, saving,
// the leaderboard interface and per-screen state. Builds and tests on Linux
// too (`swift test`), so the logic is checked without Xcode.
let package = Package(
    name: "CatLogicKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "CatLogicKit", targets: ["CatLogicKit"])],
    targets: [
        .target(name: "CatLogicKit", resources: [.copy("Resources/levels.json")]),
        .testTarget(name: "CatLogicKitTests", dependencies: ["CatLogicKit"]),
    ]
)
