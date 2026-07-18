import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';
import 'package:path/path.dart' as p;

import 'engine_host.dart';
import 'engine_status.dart';
import 'port_utils.dart';
import 'rpc_ready.dart';

/// 以**子进程**方式运行 `aria2-next` / `aria2c`，并对 127.0.0.1 暴露 JSON-RPC。
///
/// 流程：`start` → spawn → [waitForRpcReady] → running；
/// `stop` → 尽量 `aria2.shutdown` → 再 SIGTERM/SIGKILL。
///
/// iOS 不支持（用 FFI）；Android 需事先把二进制放到可执行路径。
class ProcessEngineHost implements EngineHost {
  ProcessEngineHost({
    required this.executablePath,
    this.workingDirectory,
    this.readyTimeout = const Duration(seconds: 15),
    this.stopTimeout = const Duration(seconds: 5),
    this.allocatePortIfBusy = true,
  });

  /// 引擎可执行文件绝对路径。
  final String executablePath;

  final String? workingDirectory;

  /// 等待 RPC 就绪的最长时间。
  final Duration readyTimeout;

  /// 优雅退出等待时间。
  final Duration stopTimeout;

  /// 配置端口被占用时是否自动换空闲端口。
  final bool allocatePortIfBusy;

  final _statusController = StreamController<EngineStatus>.broadcast();
  final _logController = StreamController<String>.broadcast();

  EngineStatus _status = const EngineStatus(lifecycle: EngineLifecycle.stopped);
  Process? _process;
  RpcConnectionConfig? _localRpc;
  EngineConfig? _activeConfig;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  /// true 表示我们主动 stop/kill，exitCode 回调不要标成 crashed。
  bool _intentionalStop = false;
  final List<String> _recentLogs = [];

  /// 最近 stdout/stderr 行（环形缓冲，最多约 200 行）。
  List<String> get recentLogs => List.unmodifiable(_recentLogs);

  /// 实时日志流。
  Stream<String> get logs => _logController.stream;

  @override
  Stream<EngineStatus> get status => _statusController.stream;

  @override
  EngineStatus get currentStatus => _status;

  @override
  RpcConnectionConfig? get localRpc => _localRpc;

  EngineConfig? get activeConfig => _activeConfig;

  bool get isRunning => _status.lifecycle == EngineLifecycle.running;

  @override
  Future<void> start(EngineConfig config) async {
    if (_status.lifecycle == EngineLifecycle.running ||
        _status.lifecycle == EngineLifecycle.starting) {
      return;
    }

    if (Platform.isIOS) {
      _emit(
        const EngineStatus(
          lifecycle: EngineLifecycle.unsupported,
          message: 'Process engine is not available on iOS; use FFI host.',
        ),
      );
      throw UnsupportedError('ProcessEngineHost is not supported on iOS');
    }

    final exe = File(executablePath);
    if (!await exe.exists()) {
      _emit(
        EngineStatus(
          lifecycle: EngineLifecycle.crashed,
          message: 'Engine binary not found: $executablePath',
        ),
      );
      throw FileSystemException('Engine binary not found', executablePath);
    }

    var effective = config;
    if (allocatePortIfBusy &&
        await isPortOpen(config.rpcPort, host: '127.0.0.1')) {
      final free = await findFreePort(preferred: config.rpcPort);
      effective = config.copyWith(rpcPort: free);
    }

    await Directory(effective.downloadDir).create(recursive: true);
    await Directory(p.dirname(effective.sessionPath)).create(recursive: true);
    final sessionFile = File(effective.sessionPath);
    if (!await sessionFile.exists()) {
      await sessionFile.create(recursive: true);
    }

    _intentionalStop = false;
    _emit(
      EngineStatus(
        lifecycle: EngineLifecycle.starting,
        rpcPort: effective.rpcPort,
      ),
    );

    final sessionExists = await File(effective.sessionPath).exists() &&
        await File(effective.sessionPath).length() > 0;
    final args = effective.toProcessArgs(sessionFileExists: sessionExists);
    try {
      _process = await Process.start(
        executablePath,
        args,
        workingDirectory: workingDirectory,
        mode: ProcessStartMode.normal,
        environment: _sanitizedEnv(),
      );
    } catch (e) {
      _emit(
        EngineStatus(
          lifecycle: EngineLifecycle.crashed,
          message: 'Failed to spawn engine: $e',
          rpcPort: effective.rpcPort,
        ),
      );
      rethrow;
    }

    _attachLogStreams(_process!);

    unawaited(_process!.exitCode.then((code) {
      if (_intentionalStop ||
          _status.lifecycle == EngineLifecycle.stopping ||
          _status.lifecycle == EngineLifecycle.stopped) {
        return;
      }
      _emit(
        EngineStatus(
          lifecycle: EngineLifecycle.crashed,
          message: 'Engine exited with code $code',
          pid: _process?.pid,
          rpcPort: effective.rpcPort,
        ),
      );
      _cleanupProcessRefs();
    }));

    final rpc = RpcConnectionConfig(
      host: '127.0.0.1',
      port: effective.rpcPort,
      secret: effective.rpcSecret,
    );

    try {
      await waitForRpcReady(rpc, timeout: readyTimeout);
    } catch (e) {
      _intentionalStop = true;
      await _killProcess();
      _cleanupProcessRefs();
      _emit(
        EngineStatus(
          lifecycle: EngineLifecycle.crashed,
          message: 'Engine started but RPC not ready: $e',
          rpcPort: effective.rpcPort,
        ),
      );
      rethrow;
    }

    _activeConfig = effective;
    _localRpc = rpc;
    _emit(
      EngineStatus(
        lifecycle: EngineLifecycle.running,
        pid: _process!.pid,
        rpcPort: effective.rpcPort,
      ),
    );
  }

  @override
  Future<void> stop() async {
    final process = _process;
    if (process == null) {
      _emit(const EngineStatus(lifecycle: EngineLifecycle.stopped));
      return;
    }

    _intentionalStop = true;
    _emit(
      EngineStatus(
        lifecycle: EngineLifecycle.stopping,
        pid: process.pid,
        rpcPort: _status.rpcPort,
      ),
    );

    // 优先 RPC 优雅退出（与 Motrix 类似），失败再杀进程。
    final rpc = _localRpc;
    if (rpc != null) {
      final client = Aria2Client(config: rpc);
      try {
        await client.call('aria2.shutdown').timeout(const Duration(seconds: 2));
      } catch (_) {
        try {
          await client
              .call('aria2.forceShutdown')
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          // Fall through to signals.
        }
      } finally {
        client.close();
      }
    }

    try {
      await process.exitCode.timeout(stopTimeout);
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
      }
    }

    _cleanupProcessRefs();
    _localRpc = null;
    _activeConfig = null;
    _emit(const EngineStatus(lifecycle: EngineLifecycle.stopped));
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _statusController.close();
    await _logController.close();
  }

  void _attachLogStreams(Process process) {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLogLine);
    _stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLogLine);
  }

  void _onLogLine(String line) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) return;
    _recentLogs.add(trimmed);
    if (_recentLogs.length > 200) {
      _recentLogs.removeRange(0, _recentLogs.length - 200);
    }
    if (!_logController.isClosed) {
      _logController.add(trimmed);
    }
  }

  Future<void> _killProcess() async {
    final process = _process;
    if (process == null) return;
    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }
  }

  void _cleanupProcessRefs() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _process = null;
  }

  /// 子进程环境去掉 HTTP(S)_PROXY，避免本机 RPC 被代理劫持。
  Map<String, String> _sanitizedEnv() {
    final env = Map<String, String>.from(Platform.environment);
    for (final key in const [
      'http_proxy',
      'https_proxy',
      'HTTP_PROXY',
      'HTTPS_PROXY',
      'all_proxy',
      'ALL_PROXY',
    ]) {
      env.remove(key);
    }
    env['no_proxy'] = '127.0.0.1,localhost,::1';
    env['NO_PROXY'] = '127.0.0.1,localhost,::1';
    return env;
  }

  void _emit(EngineStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
