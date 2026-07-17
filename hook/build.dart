import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    // Allow dependents that do not use FFI (e.g. chiffondb_generator running
    // its own tests) to skip the hook entirely via an environment variable.
    if (Platform.environment['CHIFFONDB_HOOK_SKIP'] == '1') return;

    final os = input.config.code.targetOS;
    final arch = input.config.code.targetArchitecture;

    final target = _resolveTarget(os, arch);
    final outFile = File(
      p.join(input.outputDirectory.toFilePath(), target.libFileName),
    );

    // Use a locally built dylib if available; otherwise download from
    // GitHub Releases.
    // Set CHIFFONDB_USE_RELEASE=1 to skip local search and always download
    // the pre-built library from GitHub Releases.
    const version = '0.2.0';
    final useRelease = Platform.environment['CHIFFONDB_USE_RELEASE'] == '1';
    final packageRoot = input.packageRoot;
    final localLib = useRelease ? null : _findLocalLib(packageRoot, os);
    if (localLib != null) {
      await localLib.copy(outFile.path);
    } else {
      final zipUri = Uri.parse(
        'https://github.com/szktty/chiffondb/releases/download/'
        'v$version/${target.zipFileName}',
      );
      await _downloadAndExtract(zipUri, target.libFileName, outFile, version);
    }

    // Dart's native_assets bundler requires a single-architecture dylib on
    // macOS/iOS. Thin the fat binary produced by the universal macOS release
    // zip down to the target architecture via lipo.
    if ((Platform.isMacOS || Platform.isIOS) && outFile.existsSync()) {
      await _thinMacOSLibIfNeeded(outFile, arch);
    }

    output.assets.code.add(
      CodeAsset(
        package: 'chiffondb',
        name: 'src/generated/chiffondb_ffi.dart',
        linkMode: DynamicLoadingBundled(),
        file: outFile.uri,
      ),
    );
  });
}

/// Describes the release asset names for a target platform.
class _Target {
  /// Name of the zip archive on GitHub Releases.
  final String zipFileName;

  /// Name of the native library file inside the zip.
  final String libFileName;

  const _Target({required this.zipFileName, required this.libFileName});
}

_Target _resolveTarget(OS os, Architecture arch) {
  return switch (os) {
    // Universal binary — arch does not matter.
    OS.macOS => const _Target(
      zipFileName: 'libchiffondb_ffi-macos-universal.zip',
      libFileName: 'libchiffondb_ffi.dylib',
    ),
    OS.linux => const _Target(
      zipFileName: 'libchiffondb_ffi-linux-x86_64.zip',
      libFileName: 'libchiffondb_ffi.so',
    ),
    OS.windows => const _Target(
      zipFileName: 'chiffondb_ffi-windows-x86_64.zip',
      libFileName: 'chiffondb_ffi.dll',
    ),
    _ => throw UnsupportedError('Unsupported OS: $os'),
  };
}

/// Looks for a locally built native library.
///
/// Search order:
/// 1. `CHIFFONDB_CORE_LIB` env var — absolute path to the dylib.
/// 2. `CHIFFONDB_CORE_ROOT` env var — path to the Rust workspace root;
///    searches `$root/target/{release,debug}/`.
/// 3. A set of conventional relative paths from [packageRoot]:
///    - `../chiffondb/chiffondb/target/` (chiffondb repo next to package)
///    - `../chiffondb/target/`           (workspace root one level up)
///    - `../../chiffondb/target/`        (workspace root two levels up)
File? _findLocalLib(Uri packageRoot, OS os) {
  final String localName;
  switch (os) {
    case OS.macOS:
      localName = 'libchiffondb_ffi.dylib';
    case OS.linux:
      localName = 'libchiffondb_ffi.so';
    case OS.windows:
      localName = 'chiffondb_ffi.dll';
    default:
      return null;
  }

  // 1. Explicit dylib path.
  final explicitLib = Platform.environment['CHIFFONDB_CORE_LIB'];
  if (explicitLib != null && explicitLib.isNotEmpty) {
    final f = File(explicitLib);
    if (f.existsSync()) return f;
  }

  // 2. Explicit workspace root.
  final explicitRoot = Platform.environment['CHIFFONDB_CORE_ROOT'];
  if (explicitRoot != null && explicitRoot.isNotEmpty) {
    for (final profile in ['release', 'debug']) {
      final f = File(p.join(explicitRoot, 'target', profile, localName));
      if (f.existsSync()) return f;
    }
  }

  // 3. Conventional relative paths.
  final candidates = [
    packageRoot.resolve('../chiffondb/chiffondb/'), // chiffondb-ffi workspace
    packageRoot.resolve('../chiffondb/'), // workspace root one level up
    packageRoot.resolve('../../chiffondb/'), // workspace root two levels up
  ];
  for (final root in candidates) {
    for (final profile in ['release', 'debug']) {
      final f = File(root.resolve('target/$profile/$localName').toFilePath());
      if (f.existsSync()) return f;
    }
  }

  return null;
}

/// Downloads a zip from [uri], extracts [entryName] from it, and writes the
/// result to [dest].
Future<void> _downloadAndExtract(
  Uri uri,
  String entryName,
  File dest,
  String version,
) async {
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw StateError('''
Failed to download the chiffondb native library.

  URL : $uri
  HTTP: ${response.statusCode}

To resolve this, choose one of the following:

  A) Build the library locally (requires Rust / Cargo):
       cd /path/to/chiffondb   # Rust workspace root
       cargo build -p chiffondb-ffi
     Then set the environment variable:
       export CHIFFONDB_CORE_LIB=/path/to/target/debug/$entryName

  B) Point to an existing build via environment variables:
       CHIFFONDB_CORE_LIB  — absolute path to the dylib
       CHIFFONDB_CORE_ROOT — path to the Rust workspace root

  C) Set CHIFFONDB_HOOK_SKIP=1 to skip the hook (FFI will not be available).

  See https://github.com/szktty/chiffondb/releases/tag/v$version for
  available pre-built binaries.
''');
  }

  final archive = ZipDecoder().decodeBytes(response.bodyBytes);
  final entry = archive.findFile(entryName);
  if (entry == null) {
    throw StateError(
      'Entry "$entryName" not found in archive downloaded from $uri',
    );
  }

  await dest.writeAsBytes(entry.content as List<int>);
}

/// Thins a fat (universal) macOS dylib to the target architecture using lipo.
///
/// The macOS release zip ships a universal binary. Dart's native_assets
/// bundler calls `otool` expecting a single-arch dylib, so we must extract
/// the correct slice before handing the file to the output.
Future<void> _thinMacOSLibIfNeeded(File lib, Architecture arch) async {
  final archName = switch (arch) {
    Architecture.arm64 => 'arm64',
    Architecture.x64 => 'x86_64',
    _ => null,
  };
  if (archName == null) return;

  final result = await Process.run('lipo', ['-info', lib.path]);
  final info = result.stdout as String;
  // Already a thin binary for this arch — nothing to do.
  if (info.contains('Non-fat file') || !info.contains('Architectures in')) {
    return;
  }

  final tmp = File('${lib.path}.thin');
  final thinResult = await Process.run('lipo', [
    lib.path,
    '-thin',
    archName,
    '-output',
    tmp.path,
  ]);
  if (thinResult.exitCode != 0) {
    throw StateError('lipo -thin failed: ${thinResult.stderr}');
  }
  await tmp.rename(lib.path);
}
