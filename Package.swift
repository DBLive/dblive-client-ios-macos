// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DBLive",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DBLive",
            targets: ["DBLive"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/socketio/socket.io-client-swift", .upToNextMinor(from: "15.2.0")),
		.package(url: "https://github.com/yannickl/AwaitKit", .upToNextMinor(from: "5.2.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "DBLive",
            dependencies: ["SocketIO", "AwaitKit"]),
        .testTarget(
            name: "DBLiveTests",
            dependencies: ["DBLive"]),
    ]
)
