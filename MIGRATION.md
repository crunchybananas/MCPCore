# MCPCore 2.0 migration (unreleased)

## Removed storage implementation

MCPCore 2.0 removes the `CSQLite` library product, target, vendored SQLite C source, system-header shim, and `@_exported import CSQLite`. Protocol types, tool metadata, agent types, templates, DTOs, and `MCPDataPersisting` retain their existing API. Database storage is a host concern; MCPCore does not need it to encode or dispatch protocol values.

This is a major-version change because 1.x consumers could import `CSQLite` directly or receive SQLite symbols implicitly through `import MCPCore`. Do not publish it as a 1.x update.

## Consumers using only protocol types

After 2.0.0 is published, change the package requirement to `from: "2.0.0"`. Keep the `MCPCore` product dependency and existing Swift imports. No persistence implementation or stored-data migration is supplied or required by this package change. Platform minimums remain macOS/iOS 26 in this cleanup.

Before release, use a local package reference or an exact reviewed commit; the README's 2.0.0 version example is not resolvable until a release is tagged.

## Peel and RAGCore

Dependency audit on November 9, 2026:

- Peel resolves MCPCore 1.6.0 and uses a 1.x version range. Its local Git package also requests MCPCore 1.x.
- RAGCore's published manifest requests MCPCore 1.x solely for the `CSQLite` product in its `RAGCore` and `SQLiteVec` targets.
- Peel has direct `import CSQLite` consumers in its RAG services.

These existing requirements exclude 2.0, so the existing releases continue to resolve their original storage dependency. Their source and lockfiles have not been changed in this cleanup. No release has been published.

The companion [RAGCore 3.0 PR](https://github.com/crunchybananas/RAGCore/pull/32) now implements the storage ownership transfer. Its tests, optimized build, and paired Swift consumer with this MCPCore branch pass. Neither major version is released yet.

Before upgrading Peel:

1. Review the companion RAGCore change, which transfers the existing SQLite source, headers, build settings, and license without changing the implementation. Its validation covers static sqlite-vec registration, database reopen, and the transferred C sources' iOS compilation; it does not claim a full Peel/iOS application build.
2. Remove RAGCore's MCPCore dependency if it still uses only the SQLite product. Publish a compatible storage-owning RAGCore release.
3. Give Peel an explicit dependency on the new storage product and explicit imports wherever it relied on the old re-export. Update Peel's RAGCore, MCPCore, and local Git package requirements together; SwiftPM cannot resolve MCPCore 1.x and 2.x simultaneously under the same package identity.
4. Run Peel's coordinated app/package builds and RAGCore's database/vector tests before updating its lockfile.

The old SQLite source remains available in MCPCore's 1.x Git history. This cleanup does not delete or migrate any application's database files.

## Validation

Run `swift test` and `swift build -c release`. `swift package describe --type json` should show one Swift library target plus its tests, with no target or package dependencies for MCPCore. The library's object symbols must not contain SQLite references.
