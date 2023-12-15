// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "KeyValueCoder",
    platforms: [
        .macOS(.v13), .iOS(.v15)
    ],
    products: [
        .library(
            name: "KeyValueCoder",
            targets: ["KeyValueCoder"]
        ),
    ],
    targets: [
        .target(
            name: "KeyValueCoder",
            path: "Sources"
        ),
        .testTarget(
            name: "KeyValueCoderTests",
            dependencies: ["KeyValueCoder"],
            path: "Tests"
        )
    ]
)
