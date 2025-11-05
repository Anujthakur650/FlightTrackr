// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlightyClone",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FlightyClone",
            targets: ["FlightyClone"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
        // Example: .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")
    ],
    targets: [
        .target(
            name: "FlightyClone",
            dependencies: [],
            path: "FlightyClone",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FlightyCloneTests",
            dependencies: ["FlightyClone"],
            path: "FlightyCloneTests"
        ),
    ]
)
