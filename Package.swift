// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "C2PASwift",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "C2PA", targets: ["C2PA"])
    ],
    targets: [
        .binaryTarget(
            name: "C2PAC",
            url: "https://github.com/copihue-studio/c2pa-swift/releases/download/0.72.3/C2PAC.xcframework.zip",
            checksum: "2c3d8ba416e8f6086c29e3a6642a7b8bef5041f7aa41e6d6a1453c8af5421528"
        ),
        .target(
            name: "C2PA",
            dependencies: ["C2PAC"],
            path: "Sources/C2PA"
        )
    ]
)
