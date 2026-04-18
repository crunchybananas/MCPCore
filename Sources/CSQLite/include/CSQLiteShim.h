// CSQLite shim — exposes the system sqlite3 headers through a distinct header
// so that importers see a stable CSQLite module whose type definitions match
// the macOS SDK that Xcode is building against.
//
// Previously this target vendored sqlite3.h + sqlite3ext.h from a specific
// SQLite release. That breaks whenever the macOS SDK's sqlite3_api_routines
// struct gains fields (e.g. `setlk_timeout` in macOS 26.3.1), because Swift's
// module verifier rejects the mismatched definitions between `SQLite3.Ext`
// (system) and `CSQLite` (vendored).
//
// Using the system headers via this shim keeps CSQLite always in sync with the
// SDK. The `[system] [extern_c]` attributes on the modulemap suppress the
// cross-module struct-equality check.

#ifndef CSQLITE_SHIM_H
#define CSQLITE_SHIM_H

#include <sqlite3.h>
#include <sqlite3ext.h>

#endif
