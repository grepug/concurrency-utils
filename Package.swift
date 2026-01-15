// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "concurrency-utils",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ConcurrencyUtils",
            targets: ["ConcurrencyUtils"]),
        .library(
            name: "ConcurrencyUtilsTestingSupport",
            targets: ["ConcurrencyUtilsTestingSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/grepug/event-source.git", branch: "master"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ConcurrencyUtils",
            dependencies: [
                .product(name: "EventSource", package: "event-source"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]),
        .target(
            name: "ConcurrencyUtilsTestingSupport",
            dependencies: ["ConcurrencyUtils"]),
        .testTarget(
            name: "ConcurrencyUtilsTests",
            dependencies: [
                "ConcurrencyUtils",
                "ConcurrencyUtilsTestingSupport",
            ]),
    ]
)
