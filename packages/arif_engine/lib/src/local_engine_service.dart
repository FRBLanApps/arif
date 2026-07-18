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

/// High-level local engine lifecycle: locate binary → start → expose RPC.
///
/// Process mode only (FFI later). Safe no-op on platforms without a binary.
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

  EngineHost? get host => _host;
  String? get resolvedBinary => _resolvedBinary;
  EngineConfig? get config => _config;
  RpcConnectionConfig? get localRpc => _host?.localRpc;
  EngineStatus get status =>
      _host?.currentStatus ??
      const EngineStatus(lifecycle: EngineLifecycle.stopped);

  Stream<EngineStatus>? get statusStream => _host?.status;

  /// Whether process-based local engine is supported on this platform.
  static bool get isProcessSupported =>
      !Platform.isIOS && !Platform.isAndroid; // Android needs staged binary first

  /// Android can use process mode once a binary is staged under app files.
  static bool get isAndroidProcessCapable => Platform.isAndroid;

  /// Resolves binary path without starting.
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

  /// Starts a managed engine if needed and returns loopback RPC config.
  ///
  /// If [reuseExistingRpc] is true and something already answers RPC on the
  /// preferred port, returns that endpoint without spawning (external aria2).
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

    if (reuseExistingRpc && await isPortOpen(port)) {
      final existing = RpcConnectionConfig(
        host: '127.0.0.1',
        port: port,
        secret: rpcSecret,
      );
      // Probe without long wait — if it's aria2, use it.
      final client = Aria2Client(config: existing);
      try {
        await client.getVersion().timeout(const Duration(seconds: 2));
        return existing;
      } catch (_) {
        // Port open but not aria2; fall through to spawn with free port.
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

    await host.start(config);
    final rpc = host.localRpc;
    if (rpc == null) {
      throw StateError('Engine started without local RPC endpoint');
    }
    return rpc;
  }

  Future<void> stop() async {
    await _host?.stop();
  }

  Future<void> dispose() async {
    if (_ownsHost) {
      await _host?.dispose();
    } else {
      await _host?.stop();
    }
    _host = null;
  }

  List<String> _defaultBundledDirs() {
    final dirs = <String>[];
    // Relative to cwd when running from monorepo / CI artifact extract.
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
    // Android / others: temp until platform channels provide filesDir.
    return p.join(Directory.systemTemp.path, 'arif');
  }
}
