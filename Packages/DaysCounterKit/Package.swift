// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DaysCounterKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "DaysCounterKit", targets: ["DaysCounterKit"]),
    ],
    targets: [
        .target(name: "DaysCounterKit"),
        .testTarget(name: "DaysCounterKitTests", dependencies: ["DaysCounterKit"]),
    ]
)
