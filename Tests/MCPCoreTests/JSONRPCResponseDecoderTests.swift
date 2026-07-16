import XCTest

@testable import MCPCore

/// Round-trip tests: everything `JSONRPCResponseBuilder` emits must decode
/// through `JSONRPCResponseDecoder`. Builder and decoder live in the same
/// module precisely so these tests pin the wire shape from both sides.
final class JSONRPCResponseDecoderTests: XCTestCase {

  private func string(_ data: Data) throws -> String {
    try XCTUnwrap(String(data: data, encoding: .utf8))
  }

  // MARK: - Round-trips with the builder

  func testToolResultRoundTripUnwrapsJSONPayload() throws {
    let json = try string(JSONRPCResponseBuilder.makeToolResult(
      id: 7, result: ["content": "Hello from the mesh", "duration": "1.4s", "count": 3]))

    let payload = JSONRPCResponseDecoder.jsonPayload(from: json)
    XCTAssertEqual(payload?["content"] as? String, "Hello from the mesh")
    XCTAssertEqual(payload?["duration"] as? String, "1.4s")
    XCTAssertEqual(payload?["count"] as? Int, 3)
    XCTAssertNil(JSONRPCResponseDecoder.error(from: json))
  }

  func testToolResultWithStringPayloadIsTextNotJSON() throws {
    // makeToolResult(result: String) puts the string straight into the text
    // field — a plain-text reply, not a JSON payload.
    let json = try string(JSONRPCResponseBuilder.makeToolResult(id: 1, result: "plain reply"))

    XCTAssertEqual(JSONRPCResponseDecoder.textPayload(from: json), "plain reply")
    XCTAssertNil(JSONRPCResponseDecoder.jsonPayload(from: json))
  }

  func testErrorRoundTripSurfacesErrorObjectAndNilsPayloads() throws {
    let json = try string(JSONRPCResponseBuilder.makeError(
      id: 7, code: JSONRPCResponseBuilder.ErrorCode.internalError, message: "Ollama is not available"))

    XCTAssertNil(JSONRPCResponseDecoder.result(from: json))
    XCTAssertNil(JSONRPCResponseDecoder.jsonPayload(from: json))
    XCTAssertNil(JSONRPCResponseDecoder.textPayload(from: json))
    let error = JSONRPCResponseDecoder.error(from: json)
    XCTAssertEqual(error?["code"] as? Int, -32603)
    XCTAssertEqual(error?["message"] as? String, "Ollama is not available")
  }

  func testToolErrorRoundTripKeepsIsErrorResultShape() throws {
    // makeToolError is a SUCCESS envelope whose payload carries the error —
    // the decoder must still hand back the payload.
    let json = try string(JSONRPCResponseBuilder.makeToolError(id: 2, message: "boom"))

    XCTAssertEqual(JSONRPCResponseDecoder.jsonPayload(from: json)?["error"] as? String, "boom")
    XCTAssertEqual(JSONRPCResponseDecoder.result(from: json)?["isError"] as? Bool, true)
  }

  // MARK: - Literal wire fixtures (guard builder + decoder against coordinated drift)

  func testLiteralEnvelopeFixtureDecodes() throws {
    let json = #"{"jsonrpc":"2.0","id":"req-1","result":{"content":[{"type":"text","text":"{\"content\":\"hi\",\"duration\":\"0.2s\"}"}],"isError":false}}"#
    let payload = JSONRPCResponseDecoder.jsonPayload(from: json)
    XCTAssertEqual(payload?["content"] as? String, "hi")
    XCTAssertEqual(payload?["duration"] as? String, "0.2s")
  }

  func testUntypedContentItemStillMatches() throws {
    // Older/plain handlers omit `type` on content items; match on the
    // presence of `text`, not the tag.
    let json = #"{"jsonrpc":"2.0","id":1,"result":{"content":[{"text":"plain reply"}]}}"#
    XCTAssertEqual(JSONRPCResponseDecoder.textPayload(from: json), "plain reply")
  }

  func testBareResultObjectFallsThroughAsPayload() throws {
    // Tools that don't use MCP content wrapping return their payload as the
    // bare `result` object.
    let json = #"{"jsonrpc":"2.0","id":1,"result":{"ok":true,"value":42}}"#
    let payload = JSONRPCResponseDecoder.jsonPayload(from: json)
    XCTAssertEqual(payload?["ok"] as? Bool, true)
    XCTAssertEqual(payload?["value"] as? Int, 42)
  }

  func testAbsentAndMalformedInputDecodeToNil() {
    for bad in [nil, "", "not json", "[1,2,3]"] as [String?] {
      XCTAssertNil(JSONRPCResponseDecoder.envelope(from: bad))
      XCTAssertNil(JSONRPCResponseDecoder.result(from: bad))
      XCTAssertNil(JSONRPCResponseDecoder.error(from: bad))
      XCTAssertNil(JSONRPCResponseDecoder.textPayload(from: bad))
      XCTAssertNil(JSONRPCResponseDecoder.jsonPayload(from: bad))
    }
  }
}
