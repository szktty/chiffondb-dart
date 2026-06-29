# Changelog

## Unreleased

- **FFI/binding change.** Expose ChiffonDB's dynamic-label API: regenerated the
  flutter_rust_bridge bindings to add `Connection.insertNodeWithDynamicLabels`,
  `addNodeLabelDynamic`, and `addEdgeLabelDynamic`, plus the
  `DynamicInsertResult { rid, assignmentsJson }` type. Unknown label names are
  minted a type id on the fly (no `applySchema` needed); each call reports
  whether a name was newly created via the returned JSON `{id, created}`
  mapping. Added `test/dynamic_labels_test.dart`. (The bindings are generated
  with rust-input `crate::api,chiffondb-core::api` — both the FFI crate and the
  re-exported core module must be scanned, or the generator silently drops the
  `Connection` methods.)
- Verified the JSON-search traversal features added in ChiffonDB
  (`feature/json-search-and-labels`): `any_key_contains` now recurses into
  `Json`-typed properties, and `filter.property` / `OrderBy.key` /
  property-reference keys accept nested `{ "path": [...] }` paths in addition to
  flat top-level keys. These are command-JSON semantics only — no FFI change.
  Added `test/traversal_search_test.dart` exercising them end-to-end.
- Fix native library loading in Flutter apps. `flutter run` / `flutter build
  macos` bundle the dylib as `chiffondb_ffi.framework/chiffondb_ffi` (named
  after the CodeAsset, no arch suffix), but `ChiffonDb.init()` only looked for
  the arch-suffixed `chiffondb_ffi-<arch>-apple-darwin.framework` name and threw
  "Failed to load the chiffondb_ffi native library". Added the non-suffixed
  framework path to the macOS/iOS candidate list.
- Widen the `archive` dependency constraint to `>=3.6.0 <5.0.0` so the package
  is compatible with toolchains that pull in `archive` 4.x (e.g. recent
  `flutter_gen`). The hook's `ZipDecoder.decodeBytes` / `findFile` /
  `ArchiveFile.content` usage is API-compatible across 3.x and 4.x.

## 0.1.0

Initial release.
