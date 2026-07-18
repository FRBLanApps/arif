import 'dart:io';

import 'package:path/path.dart' as p;

/// Candidate executable basenames (aria2-next preferred, stock aria2 fallback).
const kEngineBinaryNames = <String>[
  'aria2-next',
  'aria2-next.exe',
  'aria2c',
  'aria2c.exe',
];

/// Resolves where the local engine binary lives.
class EngineBinaryLocator {
  const EngineBinaryLocator({
    this.bundledSearchDirs = const [],
    this.environment = const {},
    this.pathEnv,
  });

  /// Extra directories to search (e.g. app assets extract dir, tool/dist).
  final List<String> bundledSearchDirs;

  /// Override env map (tests). Defaults to [Platform.environment] when empty.
  final Map<String, String> environment;

  /// Override PATH string (tests).
  final String? pathEnv;

  Map<String, String> get _env =>
      environment.isEmpty ? Platform.environment : environment;

  /// Search order:
  /// 1. `ARIF_ENGINE_PATH` / `ARIA2_PATH` absolute file
  /// 2. [bundledSearchDirs]
  /// 3. directories on PATH
  /// 4. common install prefixes (Unix)
  Future<String?> find() async {
    final fromEnv = await _fromEnvVars();
    if (fromEnv != null) return fromEnv;

    for (final dir in bundledSearchDirs) {
      final hit = await _findInDir(dir);
      if (hit != null) return hit;
    }

    final pathHit = await _fromPath();
    if (pathHit != null) return pathHit;

    if (!Platform.isWindows) {
      for (final dir in const [
        '/usr/local/bin',
        '/usr/bin',
        '/opt/homebrew/bin',
        '/snap/bin',
      ]) {
        final hit = await _findInDir(dir);
        if (hit != null) return hit;
      }
    }

    return null;
  }

  Future<String?> _fromEnvVars() async {
    for (final key in const ['ARIF_ENGINE_PATH', 'ARIA2_PATH']) {
      final value = _env[key];
      if (value == null || value.isEmpty) continue;
      final file = File(value);
      if (await file.exists()) return file.absolute.path;
    }
    return null;
  }

  Future<String?> _fromPath() async {
    final path = pathEnv ?? _env['PATH'] ?? '';
    final sep = Platform.isWindows ? ';' : ':';
    for (final dir in path.split(sep)) {
      if (dir.isEmpty) continue;
      final hit = await _findInDir(dir);
      if (hit != null) return hit;
    }
    return null;
  }

  Future<String?> _findInDir(String dir) async {
    final directory = Directory(dir);
    if (!await directory.exists()) return null;
    for (final name in kEngineBinaryNames) {
      final candidate = File(p.join(dir, name));
      if (await candidate.exists()) {
        return candidate.absolute.path;
      }
    }
    // Also match versioned release names: aria2-next-2.5.1-linux-x86_64
    try {
      await for (final entity in directory.list(followLinks: true)) {
        if (entity is! File) continue;
        final base = p.basename(entity.path);
        if (base.startsWith('aria2-next') ||
            base == 'aria2c' ||
            base == 'aria2c.exe') {
          return entity.absolute.path;
        }
      }
    } on FileSystemException {
      return null;
    }
    return null;
  }
}

/// Default data directories for a local engine under [root].
class EngineDataPaths {
  EngineDataPaths({
    required this.root,
  });

  final String root;

  String get downloadDir => p.join(root, 'downloads');
  String get sessionPath => p.join(root, 'aria2.session');
  String get confPath => p.join(root, 'aria2.conf');
  String get logPath => p.join(root, 'aria2.log');

  Future<void> ensure() async {
    await Directory(downloadDir).create(recursive: true);
    await Directory(root).create(recursive: true);
    final session = File(sessionPath);
    if (!await session.exists()) {
      await session.create(recursive: true);
    }
  }
}
