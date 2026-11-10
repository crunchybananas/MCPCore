//
//  MCPCore.swift
//  MCPCore
//
//  Core types and protocols for MCP automation framework.
//
//  This package provides:
//  - JSON-RPC 2.0 types for MCP communication
//  - Tool definitions and permissions
//  - Agent types, roles, and models
//  - Chain template definitions
//  - Data transfer objects for persistence
//  Storage implementations belong to the host app or a dedicated storage package.
//

import Foundation

// Re-export all public types
// (Swift automatically exports public types from the module)

// MARK: - Version

public enum MCPCoreVersion {
  public static let major = 2
  public static let minor = 0
  public static let patch = 0
  public static let string = "\(major).\(minor).\(patch)"
}
