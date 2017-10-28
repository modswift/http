// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftServerHttp",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "HTTP", targets: ["HTTP"])
    ],
    dependencies: [
      .package(url: "https://github.com/modswift/CApache.git", 
               from: "1.0.0")
    ],
    targets: [
      .target(name: "HTTP")
    ]
)
