# SQLite removal validation

November 9, 2026, branch `codex/remove-sqlite`, based on upstream `615081f`.

- `swift test`: 28 tests passed, zero failures.
- `swift build -c release`: passed.
- `xcrun swiftc -typecheck -parse-as-library -module-name MCPCore -sdk <iphoneos SDK> -target arm64-apple-ios26.0 Sources/MCPCore/*.swift`: passed. This is an iOS compile check, not a device runtime test.
- Parsed `swift package describe --type json`: only MCPCore and its tests; library has Swift sources only, no target or package dependencies.
- Inspected undefined symbols in `.build/release/libMCPCore.a`: no SQLite, inflate, or deflate references.
- `git diff --check`: passed.

Existing compiler warnings remain: `AnyCodable.value` and `MCPToolDefinition.inputSchema` use non-Sendable `Any` in Sendable types, and one JSON-RPC builder local could be `let`. This cleanup preserves the existing Swift 5 language mode; it does not claim Swift 6 strict-concurrency compatibility.

No Peel build or database migration was attempted. Its 1.x requirement remains unchanged; see MIGRATION.md for the RAGCore storage migration needed before a 2.x upgrade. No application was launched or restarted. No package version was published.

Disk: about 165.5 GiB free before and 165.2 GiB after verification, above the 30 GiB reserve. Reused the existing ignored `.build` incremental cache, retained for subsequent package work. No disposable checkout or scratch directory was created. Compact command logs remain in `.build/sqlite-cleanup-*` and can be removed after review; no release archives were created.

Follow-up: the paired consumer against RAGCore storage-ownership commit `59a2037` passed JSON-RPC round trip, SQLite 3.47.2 with FTS5/RTREE, sqlite-vec initialization, and database reopen. See [RAGCore PR 32](https://github.com/crunchybananas/RAGCore/pull/32) for its tests and reproduction source.
