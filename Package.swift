// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "MCPCore",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [
    .library(name: "MCPCore", targets: ["MCPCore"]),
  ],
  targets: [
    .target(name: "MCPCore"),
    .testTarget(name: "MCPCoreTests", dependencies: ["MCPCore"]),
  ]
)
