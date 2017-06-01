// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "mods_httpapi",

    dependencies: [
      .Package(url: "../..", 
               majorVersion: 0)
    ]
)
