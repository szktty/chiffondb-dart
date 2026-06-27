# Changelog

## Unreleased

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
