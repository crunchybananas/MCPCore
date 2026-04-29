import XCTest
@testable import MCPCore

final class MCPCoreTests: XCTestCase {

  // MARK: - JSON-RPC Tests

  func testJSONRPCIdString() throws {
    let id = JSONRPCId.string("test-123")
    XCTAssertEqual(id, .string("test-123"))

    let data = try JSONEncoder().encode(id)
    let decoded = try JSONDecoder().decode(JSONRPCId.self, from: data)
    XCTAssertEqual(decoded, id)
  }

  func testJSONRPCIdNumber() throws {
    let id = JSONRPCId.number(42)
    XCTAssertEqual(id.anyValue as? Int, 42)

    let data = try JSONEncoder().encode(id)
    let decoded = try JSONDecoder().decode(JSONRPCId.self, from: data)
    XCTAssertEqual(decoded, id)
  }

  func testJSONRPCError() {
    let error = JSONRPCError.invalidParams("Missing required field")
    XCTAssertEqual(error.code, -32602)
    XCTAssertTrue(error.message.contains("Missing"))
  }

  // MARK: - Tool Definition Tests

  func testToolCategory() {
    XCTAssertEqual(MCPToolCategory.chains.displayName, "Chains")
    XCTAssertEqual(MCPToolCategory.rag.displayName, "Local RAG")
    XCTAssertTrue(MCPToolCategory.allCases.count > 5)
  }

  func testToolGroup() {
    XCTAssertEqual(MCPToolGroup.screenshots.displayName, "Screenshots")
    XCTAssertEqual(MCPToolGroup.mutating.displayName, "Mutating")
  }

  // MARK: - Agent Type Tests

  func testAgentRole() {
    XCTAssertEqual(MCPAgentRole.planner.displayName, "Planner")
    XCTAssertFalse(MCPAgentRole.planner.canWrite)
    XCTAssertTrue(MCPAgentRole.implementer.canWrite)
    XCTAssertFalse(MCPAgentRole.reviewer.canWrite)
  }

  func testAgentRoleFromString() {
    XCTAssertEqual(MCPAgentRole.fromString("planner"), .planner)
    XCTAssertEqual(MCPAgentRole.fromString("IMPLEMENTER"), .implementer)
    XCTAssertNil(MCPAgentRole.fromString("invalid"))
  }

  // MARK: - Model Tests

  func testCopilotModel() {
    XCTAssertEqual(MCPCopilotModel.claudeSonnet45.displayName, "Claude Sonnet 4.5")
    XCTAssertEqual(MCPCopilotModel.gpt41.premiumCost, 0)
    XCTAssertTrue(MCPCopilotModel.gpt41.isFree)
    XCTAssertFalse(MCPCopilotModel.claudeOpus45.isFree)
  }

  func testCopilotModelFamily() {
    XCTAssertTrue(MCPCopilotModel.claudeSonnet45.isClaude)
    XCTAssertTrue(MCPCopilotModel.gpt51.isGPT)
    XCTAssertTrue(MCPCopilotModel.gemini3Pro.isGemini)
  }

  func testCopilotModel47Family() {
    XCTAssertEqual(MCPCopilotModel.claudeOpus47.rawValue, "claude-opus-4-7")
    XCTAssertEqual(MCPCopilotModel.claudeOpus47.shortName, "Opus 4.7")
    XCTAssertTrue(MCPCopilotModel.claudeOpus47.isClaude)
    XCTAssertEqual(MCPCopilotModel.claudeSonnet47.rawValue, "claude-sonnet-4-7")
    XCTAssertEqual(MCPCopilotModel.claudeHaiku47.rawValue, "claude-haiku-4-7")
  }

  /// Earlier MCPCore releases shipped raw values with dot-formatted version
  /// numbers ("claude-opus-4.6"). Persisted state from those builds must
  /// still resolve so users don't lose their model picks on upgrade.
  func testCopilotModelLegacyDotFormatResolves() {
    XCTAssertEqual(MCPCopilotModel.fromString("claude-opus-4.6"), .claudeOpus46)
    XCTAssertEqual(MCPCopilotModel.fromString("claude-haiku-4.5"), .claudeHaiku45)
    XCTAssertEqual(MCPCopilotModel.fromString("gpt-5.1-codex"), .gpt51Codex)
    XCTAssertEqual(MCPCopilotModel.fromString("gpt-4.1"), .gpt41)
  }

  func testCopilotModelDescriptor() {
    let opus47 = MCPCopilotModel.claudeOpus47.descriptor
    XCTAssertEqual(opus47.id, "claude-opus-4-7")
    XCTAssertEqual(opus47.displayName, "Claude Opus 4.7")
    XCTAssertEqual(opus47.family, .claude)
    XCTAssertEqual(opus47.costTier, .premium)
    // Claude family is servable via either CLI; Copilot CLI also supports it.
    XCTAssertTrue(opus47.providers.contains(.copilotCLI))
    XCTAssertTrue(opus47.providers.contains(.claudeCLI))

    // GPT family is Copilot-CLI only.
    let gpt51 = MCPCopilotModel.gpt51.descriptor
    XCTAssertEqual(gpt51.providers, [.copilotCLI])

    // Builtins cover every enum case.
    XCTAssertEqual(MCPCopilotModelDescriptor.builtins.count, MCPCopilotModel.allCases.count)
  }

  func testCopilotModelDescriptorRoundTripsJSON() throws {
    let descriptor = MCPCopilotModelDescriptor(
      id: "claude-opus-4-7",
      displayName: "Claude Opus 4.7",
      shortName: "Opus 4.7",
      family: .claude,
      premiumCost: 3.0,
      providers: [.copilotCLI, .claudeCLI],
      releasedAt: "2026-04-29",
      deprecatedAt: nil,
      notes: "Test entry"
    )
    let data = try JSONEncoder().encode(descriptor)
    let decoded = try JSONDecoder().decode(MCPCopilotModelDescriptor.self, from: data)
    XCTAssertEqual(decoded, descriptor)
  }

  // MARK: - Chain Template Tests

  func testChainTemplate() {
    let template = MCPChainTemplate(
      name: "Test Template",
      description: "A test",
      steps: [
        MCPAgentStepTemplate(role: .planner, model: .claudeSonnet45, name: "Planner"),
        MCPAgentStepTemplate(role: .implementer, model: .gpt41, name: "Implementer")
      ]
    )

    XCTAssertEqual(template.name, "Test Template")
    XCTAssertEqual(template.steps.count, 2)
    XCTAssertEqual(template.estimatedTotalCost, 1.0) // Sonnet=1.0, GPT-4.1=0
  }

  func testBuiltInTemplates() {
    let templates = MCPChainTemplate.builtInTemplates
    XCTAssertFalse(templates.isEmpty)
    XCTAssertTrue(templates.contains { $0.name == "Code Review" })
    XCTAssertTrue(templates.contains { $0.name == "Parallel Validation" })
  }

  // MARK: - DTO Tests

  func testMCPRunRecordDTO() throws {
    let record = MCPRunRecordDTO(
      chainId: "chain-123",
      templateName: "Test",
      prompt: "Fix the bug",
      success: true,
      resultCount: 3
    )

    let data = try JSONEncoder().encode(record)
    let decoded = try JSONDecoder().decode(MCPRunRecordDTO.self, from: data)

    XCTAssertEqual(decoded.chainId, "chain-123")
    XCTAssertEqual(decoded.templateName, "Test")
    XCTAssertTrue(decoded.success)
  }

  // MARK: - Framework Hint Tests

  func testFrameworkHint() {
    XCTAssertFalse(MCPFrameworkHint.swift.instructions.isEmpty)
    XCTAssertTrue(MCPFrameworkHint.auto.instructions.isEmpty)
  }
}
