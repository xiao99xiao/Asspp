// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppleTVSupportTests",
    platforms: [.macOS("15.0")],
    dependencies: [
        .package(url: "https://github.com/Lakr233/ApplePackage", exact: "1.2.7"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20"),
    ],
    targets: [
        .target(name: "PackageModel", dependencies: [
            .product(name: "ApplePackage", package: "ApplePackage"),
        ], path: "Sources"),
        .testTarget(name: "PackageModelTests", dependencies: [
            "PackageModel",
            .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        ], path: "Tests"),
    ]
)
