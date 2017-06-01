import PackageDescription

let package = Package(
    name: "mods_httpapi",

    dependencies: [
      .Package(url: "../..", 
               majorVersion: 0)
    ]
)
