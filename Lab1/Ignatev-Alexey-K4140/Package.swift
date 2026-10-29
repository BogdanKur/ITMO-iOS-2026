// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Lab1",
    products: [
        .library(name: "Lab1Core", targets: ["Lab1Core"]),
        .executable(name: "Lab1Demo", targets: ["Lab1Demo"])
    ],
    targets: [
        .target(name: "Lab1Core"),
        .executableTarget(name: "Lab1Demo", dependencies: ["Lab1Core"]),
        .testTarget(name: "Lab1CoreTests", dependencies: ["Lab1Core"])
    ]
)
