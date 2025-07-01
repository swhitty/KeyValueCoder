// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "KeyValueCoder",
    platforms: [
        .macOS(.v13), .iOS(.v15), .tvOS(.v15), .watchOS(.v8)
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
            path: "Sources",
            swiftSettings: .upcomingFeatures
        ),
        .testTarget(
            name: "KeyValueCoderTests",
            dependencies: ["KeyValueCoder"],
            path: "Tests",
            swiftSettings: .upcomingFeatures
        )
    ]
)

extension Array where Element == SwiftSetting {

    static var upcomingFeatures: [SwiftSetting] {
        [
            .enableUpcomingFeature("ExistentialAny"),
            .enableExperimentalFeature("StrictConcurrency")
        ]
    }
}
