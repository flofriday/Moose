// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Moose",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0")),
//        .package(url: "https://github.com/andybest/linenoise-swift", .upToNextMajor(from: "0.0.3")),
//        .package(url: "https://github.com/objecthub/swift-commandlinekit", .upToNextMajor(from: "0.3.4")),s
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "Moose",
            dependencies: ["Rainbow"]),
        .testTarget(
            name: "MooseTests",
            dependencies: ["Moose", "Rainbow"]),

    ])
