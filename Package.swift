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
            url: "https://github.com/copihue-studio/c2pa-swift/releases/download/0.72.1/C2PAC.xcframework.zip",
            checksum: "7049bc6463478f7e1912e5b931bf219511df0ba1e75052873b451088075b522c"
        ),
        .target(
            name: "C2PA",
            dependencies: ["C2PAC"],
            path: "Sources/C2PA"
        )
    ]
)
