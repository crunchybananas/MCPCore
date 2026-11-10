// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "MCPCore",
  platforms: [.macOS("26"), .iOS("26")],
  products: [
    .library(name: "MCPCore", targets: ["MCPCore"]),
  ],
  targets: [
    .target(name: "MCPCore"),
    .testTarget(name: "MCPCoreTests", dependencies: ["MCPCore"]),
  ]
)
