// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VistaRest",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VistaRest", targets: ["VistaRest"])
    ],
    targets: [
        .executableTarget(
            name: "VistaRest",
            path: "Sources/VistaRest"
        )
    ]
)
