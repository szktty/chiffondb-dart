import 'dart:ffi';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'generated/frb_generated.dart';

/// Initializes ChiffonDB by loading the native library built by the
/// package hook and registered via native_assets.
///
/// Call this once before using any [Connection] APIs:
/// ```dart
/// await ChiffonDb.init();
/// final db = await Connection.openInMemory();
/// ```
class ChiffonDb {
  ChiffonDb._();

  /// Initializes the native library.
  ///
  /// On supported platforms the library is loaded from the native_assets
  /// output directory. Throws [UnsupportedError] on unsupported platforms.
  static Future<void> init() async {
    await RustLib.init(externalLibrary: _openNativeLibrary());
  }

  // Opens the native library by trying each candidate path in order.
  //
  // flutter_rust_bridge loads the library via DynamicLibrary.lookup (not the
  // @Native assetId mechanism), so the native_assets mapping written by
  // hooks_runner is not resolved automatically. We must therefore open the
  // bundled library explicitly — `.dart_tool/lib/libchiffondb_ffi.{so,dylib}`,
  // the path hook/build.dart's CodeAsset is copied to — alongside local dev
  // builds. Passing externalLibrary: null would not help: the frb default
  // loader only tries the (stale) ioDirectory and the bare file name.
  static ExternalLibrary _openNativeLibrary() {
    if (Platform.isAndroid) {
      return ExternalLibrary.open('libchiffondb_ffi.so');
    }

    final candidates = _libraryCandidates();
    for (final name in candidates) {
      try {
        return ExternalLibrary.open(name);
      } catch (_) {
        // Try the next candidate.
      }
    }

    throw StateError(
      'Failed to load the chiffondb_ffi native library on '
      '${Platform.operatingSystem} (${Abi.current()}). '
      'Tried: ${candidates.join(', ')}',
    );
  }

  /// Builds the ordered list of native library names/paths to try.
  ///
  /// The packaged (bundled) names use the arch-suffixed naming produced by
  /// `hook/build.dart` (`_resolveTarget`) and `release.yml`. The triple
  /// strings (`apple-darwin` / `unknown-linux-gnu` / `pc-windows-msvc`) and
  /// arch names (`aarch64` / `x86_64`) MUST stay in sync with those.
  static List<String> _libraryCandidates() {
    final env = Platform.environment['CHIFFONDB_CORE_LIB'];
    final arch = _rustArch();
    final candidates = <String>[];

    if (env != null && env.isNotEmpty) {
      candidates.add(env);
    }

    if (Platform.isMacOS || Platform.isIOS) {
      // Development build: cargo workspace output in the neighbouring chiffondb
      // repo. `dart test` runs with cwd = chiffondb-dart/.
      // Mirrors the search order in hook/build.dart _findLocalLib().
      candidates
        ..add('../chiffondb/chiffondb/target/debug/libchiffondb_ffi.dylib')
        ..add('../chiffondb/chiffondb/target/release/libchiffondb_ffi.dylib')
        ..add('../chiffondb/target/debug/libchiffondb_ffi.dylib')
        ..add('../chiffondb/target/release/libchiffondb_ffi.dylib')
        ..add('../../chiffondb/target/debug/libchiffondb_ffi.dylib')
        ..add('../../chiffondb/target/release/libchiffondb_ffi.dylib');

      // hook/build.dart output: `.dart_tool/lib/` relative to package root.
      candidates.add('.dart_tool/lib/libchiffondb_ffi.dylib');

      // Packaged build: bundled framework name (resolved via @rpath).
      String framework(String a) =>
          'chiffondb_ffi-$a-apple-darwin.framework/'
          'chiffondb_ffi-$a-apple-darwin';
      if (arch != null) {
        candidates.add(framework(arch));
      } else {
        candidates
          ..add(framework('aarch64'))
          ..add(framework('x86_64'));
      }

      candidates.add('libchiffondb_ffi.dylib');
      return candidates;
    }

    if (Platform.isLinux) {
      candidates
        ..add('../chiffondb/chiffondb/target/debug/libchiffondb_ffi.so')
        ..add('../chiffondb/chiffondb/target/release/libchiffondb_ffi.so')
        ..add('../chiffondb/target/debug/libchiffondb_ffi.so')
        ..add('../chiffondb/target/release/libchiffondb_ffi.so')
        ..add('../../chiffondb/target/debug/libchiffondb_ffi.so')
        ..add('../../chiffondb/target/release/libchiffondb_ffi.so')
        // hook/build.dart output: `.dart_tool/lib/` relative to package root.
        ..add('.dart_tool/lib/libchiffondb_ffi.so')
        ..add('libchiffondb_ffi.so');
      return candidates;
    }

    if (Platform.isWindows) {
      candidates
        ..add('.dart_tool/lib/chiffondb_ffi.dll')
        ..add('chiffondb_ffi.dll');
      return candidates;
    }

    throw UnsupportedError(
      'ChiffonDB is not supported on ${Platform.operatingSystem}.',
    );
  }

  /// Maps the current ABI to the rust target arch name used in bundle names.
  ///
  /// Returns `'aarch64'` / `'x86_64'`, or `null` when the arch is unknown
  /// (callers then try all known arch candidates).
  static String? _rustArch() {
    final abi = Abi.current();
    if (abi == Abi.macosArm64 ||
        abi == Abi.iosArm64 ||
        abi == Abi.linuxArm64 ||
        abi == Abi.windowsArm64 ||
        abi == Abi.androidArm64) {
      return 'aarch64';
    }
    if (abi == Abi.macosX64 ||
        abi == Abi.iosX64 ||
        abi == Abi.linuxX64 ||
        abi == Abi.windowsX64 ||
        abi == Abi.androidX64) {
      return 'x86_64';
    }
    return null;
  }
}
