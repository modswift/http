// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SwiftServerHttp",
    dependencies: [
      .Package(url: "https://github.com/modswift/CApache.git", 
               majorVersion: 1, minor: 0)
    ]
)
