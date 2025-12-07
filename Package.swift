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
            url: "https://github.com/copihue-studio/c2pa-swift/releases/download/0.72.2/C2PAC.xcframework.zip",
            checksum: "a28f64f014592200b52a8549f6caca3eebb361e40553210118669dc77fcd3677"
        ),
        .target(
            name: "C2PA",
            dependencies: ["C2PAC"],
            path: "Sources/C2PA"
        )
    ]
)
