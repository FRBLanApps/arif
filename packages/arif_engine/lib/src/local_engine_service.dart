import 'dart:async';
import 'dart:io';

import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';
import 'package:path/path.dart' as p;

import 'engine_host.dart';
import 'engine_paths.dart';
import 'engine_status.dart';
import 'port_utils.dart';
import 'process_engine_host.dart';

/// 本地引擎的高层入口：找二进制 →（可选）spawn → 返回回环 RPC。
///
/// [ensureRunning] 决策顺序：
/// 1. 已有我们管理且端口匹配的 Host → 直接复用
/// 2. 端口上已有能 `getVersion` 的 aria2 → **复用外部进程**（不 spawn）
/// 3. 否则 locate 二进制并 [ProcessEngineHost.start]
///
/// 仅进程模式；iOS FFI 另说。
class LocalEngineService {
  LocalEngineService({
    EngineBinaryLocator? locator,
    String? dataRoot,
    this.defaultRpcPort = 6800,
    this.rpcSecret,
    EngineHost? host,
  })  : _baseLocator = locator ?? const EngineBinaryLocator(),
        _dataRoot = dataRoot,
        _injectedHost = host;

  final EngineBinaryLocator _baseLocator;
  final String? _dataRoot;
  final int defaultRpcPort;
  final String? rpcSecret;
  final EngineHost? _injectedHost;

  EngineHost? _host;
  String? _resolvedBinary;
  EngineConfig? _config;
  bool _ownsHost = false;

  /// 是否由本服务 spawn（外部复用的 aria2 为 false，断开时不要误杀用户进程）。
  bool _spawnedByUs = false;

  EngineHost? get host => _host;
  String? get resolvedBinary => _resolvedBinary;
  EngineConfig? get config => _config;
  RpcConnectionConfig? get localRpc => _host?.localRpc;

  /// 仅当我们托管的进程在跑时为 true（复用外部 RPC 时为 false）。
  bool get isManagedRunning =>
      _spawnedByUs && (_host?.currentStatus.isRunning ?? false);

  EngineStatus get status =>
      _host?.currentStatus ??
      const EngineStatus(lifecycle: EngineLifecycle.stopped);

  Stream<EngineStatus>? get statusStream => _host?.status;

  /// Whether process-based local engine is supported on this platform.
  static bool get isProcessSupported =>
      !Platform.isIOS && !Platform.isAndroid;

  static bool get isAndroidProcessCapable => Platform.isAndroid;

  Future<String?> locateBinary({List<String> extraSearchDirs = const []}) async {
    final dataRoot = _dataRoot;
    final locator = EngineBinaryLocator(
      bundledSearchDirs: [
        ...extraSearchDirs,
        if (dataRoot != null) p.join(dataRoot, 'engine'),
        ..._baseLocator.bundledSearchDirs,
        ..._defaultBundledDirs(),
      ],
      environment: _baseLocator.environment,
      pathEnv: _baseLocator.pathEnv,
    );
    final path = await locator.find();
    _resolvedBinary = path;
    return path;
  }

  /// 确保本地有可用 RPC，返回应连接的 [RpcConnectionConfig]。
  ///
  /// [reuseExistingRpc]：端口上已有 aria2 则不启动新进程。
  Future<RpcConnectionConfig> ensureRunning({
    bool reuseExistingRpc = true,
    int? rpcPort,
    String? downloadDir,
    String? sessionPath,
    String? secret,
    List<String> extraSearchDirs = const [],
    List<String> extraArgs = const [],
  }) async {
    final port = rpcPort ?? defaultRpcPort;
    final rpcSecret = secret ?? this.rpcSecret;

    // Already managing a live host on the requested port — reuse it.
    final existingHost = _host;
    final existingRpc = existingHost?.localRpc;
    if (existingHost != null &&
        existingHost.currentStatus.isRunning &&
        existingRpc != null &&
        existingRpc.port == port &&
        existingRpc.secret == rpcSecret) {
      _spawnedByUs = true;
      return existingRpc;
    }

    // Managed host exists but config differs — stop before re-spawn.
    if (existingHost != null) {
      await stop();
    }

    if (reuseExistingRpc && await isPortOpen(port)) {
      final existing = RpcConnectionConfig(
        host: '127.0.0.1',
        port: port,
        secret: rpcSecret,
      );
      final client = Aria2Client(config: existing);
      try {
        await client.getVersion().timeout(const Duration(seconds: 2));
        _spawnedByUs = false;
        return existing;
      } catch (_) {
        // Port open but not aria2 (or wrong secret); fall through to spawn.
      } finally {
        client.close();
      }
    }

    if (Platform.isIOS) {
      throw UnsupportedError(
        'Local process engine is not supported on iOS (use FFI later).',
      );
    }

    final binary = _resolvedBinary ??
        await locateBinary(extraSearchDirs: extraSearchDirs);
    if (binary == null) {
      throw StateError(
        'aria2-next / aria2c binary not found. '
        'Install aria2, set ARIF_ENGINE_PATH, or place a binary under tool/dist/engine.',
      );
    }

    final root = _dataRoot ?? await _defaultDataRoot();
    final paths = EngineDataPaths(root: root);
    await paths.ensure();

    final config = EngineConfig(
      downloadDir: downloadDir ?? paths.downloadDir,
      sessionPath: sessionPath ?? paths.sessionPath,
      rpcPort: port,
      rpcSecret: rpcSecret,
      extraArgs: [
        '--quiet=true',
        '--console-log-level=warn',
        ...extraArgs,
      ],
    );

    final host = _injectedHost ??
        ProcessEngineHost(
          executablePath: binary,
          workingDirectory: root,
        );
    _ownsHost = _injectedHost == null;
    _host = host;
    _config = config;

    try {
      await host.start(config);
    } catch (_) {
      _host = null;
      _spawnedByUs = false;
      rethrow;
    }

    final rpc = host.localRpc;
    if (rpc == null) {
      await stop();
      throw StateError('Engine started without local RPC endpoint');
    }
    _spawnedByUs = true;
    return rpc;
  }

  Future<void> stop() async {
    await _host?.stop();
    _spawnedByUs = false;
  }

  Future<void> dispose() async {
    if (_ownsHost) {
      await _host?.dispose();
    } else {
      await _host?.stop();
    }
    _host = null;
    _spawnedByUs = false;
  }

  List<String> _defaultBundledDirs() {
    final dirs = <String>[];
    dirs.add(p.join(Directory.current.path, 'tool', 'dist', 'engine'));
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      dirs.add(p.join(exeDir, 'engine'));
      dirs.add(exeDir);
    } catch (_) {}
    return dirs;
  }

  Future<String> _defaultDataRoot() async {
    final dataRoot = _dataRoot;
    if (dataRoot != null) return dataRoot;
    if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
      final xdg = Platform.environment['XDG_DATA_HOME'];
      final base = xdg ?? p.join(home, '.local', 'share');
      return p.join(base, 'arif');
    }
    if (Platform.isWindows) {
      final appData =
          Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
      return p.join(appData, 'arif');
    }
    return p.join(Directory.systemTemp.path, 'arif');
  }
}
