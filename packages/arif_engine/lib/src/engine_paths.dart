import 'dart:io';

import 'package:path/path.dart' as p;

/// 查找本地引擎可执行文件时的候选文件名（优先 aria2-next）。
const kEngineBinaryNames = <String>[
  'aria2-next',
  'aria2-next.exe',
  'aria2c',
  'aria2c.exe',
];

/// 解析本机 `aria2-next` / `aria2c` 路径。
///
/// 搜索顺序见 [find]。测试可注入 [environment] / [pathEnv] / [bundledSearchDirs]。
class EngineBinaryLocator {
  const EngineBinaryLocator({
    this.bundledSearchDirs = const [],
    this.environment = const {},
    this.pathEnv,
  });

  /// 额外搜索目录（如 `tool/dist/engine`、App 解压目录）。
  final List<String> bundledSearchDirs;

  /// 非空时覆盖 [Platform.environment]（单测用）。
  final Map<String, String> environment;

  /// 非空时覆盖 PATH 字符串（单测用）。
  final String? pathEnv;

  Map<String, String> get _env =>
      environment.isEmpty ? Platform.environment : environment;

  /// 返回绝对路径；找不到返回 null。
  ///
  /// 顺序：
  /// 1. 环境变量 `ARIF_ENGINE_PATH` / `ARIA2_PATH`（必须是已存在文件）
  /// 2. [bundledSearchDirs]
  /// 3. PATH 中各目录
  /// 4. 常见 Unix 安装前缀
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

  /// 在目录内找标准名，或 `aria2-next-*` 版本化 release 文件名。
  Future<String?> _findInDir(String dir) async {
    final directory = Directory(dir);
    if (!await directory.exists()) return null;
    for (final name in kEngineBinaryNames) {
      final candidate = File(p.join(dir, name));
      if (await candidate.exists()) {
        return candidate.absolute.path;
      }
    }
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

/// 本地引擎数据目录布局：downloads + session 等。
class EngineDataPaths {
  EngineDataPaths({
    required this.root,
  });

  /// 根目录，例如 `~/.local/share/arif`。
  final String root;

  String get downloadDir => p.join(root, 'downloads');
  String get sessionPath => p.join(root, 'aria2.session');
  String get confPath => p.join(root, 'aria2.conf');
  String get logPath => p.join(root, 'aria2.log');

  /// 创建下载目录与空 session 文件（若不存在）。
  Future<void> ensure() async {
    await Directory(downloadDir).create(recursive: true);
    await Directory(root).create(recursive: true);
    final session = File(sessionPath);
    if (!await session.exists()) {
      await session.create(recursive: true);
    }
  }
}
