// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "CameraKit",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "CameraKit",
            targets: ["CameraKit"]
        )
    ],
    targets: [
        .target(
            name: "CameraKit",
            path: "CameraKit/CameraKit",
            exclude: ["Info.plist"]
        )
    ]
)
