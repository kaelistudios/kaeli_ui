// swift-tools-version: 5.9
// kaeli_ui con Swift Package Manager (KaeliBadge, 0.10.0). Las apps con CocoaPods usan ios/kaeli_ui.podspec.

import PackageDescription

let package = Package(
    name: "kaeli_ui",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "kaeli-ui", targets: ["kaeli_ui"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "kaeli_ui",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
