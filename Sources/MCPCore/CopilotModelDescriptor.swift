//
//  CopilotModelDescriptor.swift
//  MCPCore
//
//  Data-driven description of a model the Copilot CLI (or Claude CLI) can
//  serve. Lets clients build model registries that merge:
//
//    1. Live discovery from the installed CLI binary (highest priority)
//    2. Remote catalogs (e.g. Firestore config/copilot_models)
//    3. Per-machine override files
//    4. Bundled builtins (`MCPCopilotModelDescriptor.builtins`)
//
//  The MCPCopilotModel enum stays as the offline-safe set of "this binary
//  always knows about these"; descriptors are how anything new arrives.
//

import Foundation

/// Identifies which CLI surface can run a given model.
public enum MCPCopilotModelProvider: String, Codable, Sendable, CaseIterable {
  /// Routed through the Copilot CLI (`copilot`). All families can run here.
  case copilotCLI = "copilot-cli"
  /// Routed through the Claude CLI (`claude`). Claude family only.
  case claudeCLI = "claude-cli"
}

/// A model + everything UIs and routers need to render and route it without
/// re-deriving anything from a hardcoded enum.
public struct MCPCopilotModelDescriptor: Codable, Hashable, Sendable, Identifiable {
  /// Canonical model id — Anthropic / OpenAI / Google convention
  /// (e.g. `claude-opus-4-7`, `gpt-5-2`, `gemini-3-pro-preview`).
  public let id: String

  /// Human-readable name (e.g. "Claude Opus 4.7").
  public let displayName: String

  /// Compact label for tight UI (e.g. "Opus 4.7").
  public let shortName: String

  /// Family this model belongs to.
  public let family: MCPCopilotModel.ModelFamily

  /// Premium-request cost multiplier (0 = free tier).
  public let premiumCost: Double

  /// CLIs that can serve this model. A model is "available" on a machine
  /// when at least one provider in this set has a working CLI.
  public let providers: [MCPCopilotModelProvider]

  /// Optional release date (ISO-8601). Lets registries surface "new" badges
  /// and lets recommenders prefer newer models when costs tie.
  public let releasedAt: String?

  /// When set, model is hidden from pickers and recommenders. Existing
  /// daemons pinned to it keep working until they're re-pointed.
  public let deprecatedAt: String?

  /// Free-form notes — release-channel hints, throughput caveats, etc.
  /// Surfaces in registry tooling but is not parsed.
  public let notes: String?

  public init(
    id: String,
    displayName: String,
    shortName: String,
    family: MCPCopilotModel.ModelFamily,
    premiumCost: Double,
    providers: [MCPCopilotModelProvider],
    releasedAt: String? = nil,
    deprecatedAt: String? = nil,
    notes: String? = nil
  ) {
    self.id = id
    self.displayName = displayName
    self.shortName = shortName
    self.family = family
    self.premiumCost = premiumCost
    self.providers = providers
    self.releasedAt = releasedAt
    self.deprecatedAt = deprecatedAt
    self.notes = notes
  }

  /// Cost tier derived from `premiumCost` — same thresholds as
  /// `MCPCopilotModel.costTier` so registries can mix-and-match.
  public var costTier: MCPCopilotModel.CostTier {
    if premiumCost == 0 { return .free }
    if premiumCost < 1.0 { return .low }
    if premiumCost == 1.0 { return .standard }
    return .premium
  }

  public var isFree: Bool { premiumCost == 0 }
  public var isDeprecated: Bool { deprecatedAt != nil }
}

// MARK: - Builtin descriptors

extension MCPCopilotModelDescriptor {
  /// Every model the enum knows about, projected as a descriptor.
  /// Registries treat this as the lowest-priority source — anything in
  /// Firestore, an override file, or live CLI discovery wins.
  public static let builtins: [MCPCopilotModelDescriptor] = MCPCopilotModel.allCases.map { $0.descriptor }
}

// MARK: - MCPCopilotModel <-> Descriptor bridge

extension MCPCopilotModel {
  /// Project this enum case as a descriptor. Providers are derived from
  /// `requiredProvider` plus the well-known fact that Copilot CLI also
  /// serves Claude models.
  public var descriptor: MCPCopilotModelDescriptor {
    let providers: [MCPCopilotModelProvider]
    switch modelFamily {
    case .claude: providers = [.copilotCLI, .claudeCLI]
    case .gpt, .gemini: providers = [.copilotCLI]
    }
    return MCPCopilotModelDescriptor(
      id: rawValue,
      displayName: displayName,
      shortName: shortName,
      family: modelFamily,
      premiumCost: premiumCost,
      providers: providers,
      releasedAt: nil,
      deprecatedAt: nil,
      notes: nil
    )
  }
}
