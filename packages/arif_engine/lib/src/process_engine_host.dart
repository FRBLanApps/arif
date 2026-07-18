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

/// Spawns `aria2-next` / `aria2c` as a child process and exposes loopback RPC.
///
/// Used on Linux, Windows, and Android (with a pre-staged binary).
/// Not used on iOS (FFI later).
class ProcessEngineHost implements EngineHost {
  ProcessEngineHost({
    required this.executablePath,
    this.workingDirectory,
    this.readyTimeout = const Duration(seconds: 15),
    this.stopTimeout = const Duration(seconds: 5),
    this.allocatePortIfBusy = true,
  });

  /// Absolute path to the engine binary.
  final String executablePath;

  final String? workingDirectory;
  final Duration readyTimeout;
  final Duration stopTimeout;

  /// When true, if [EngineConfig.rpcPort] is occupied, pick another free port.
  final bool allocatePortIfBusy;

  final _statusController = StreamController<EngineStatus>.broadcast();
  final _logController = StreamController<String>.broadcast();

  EngineStatus _status = const EngineStatus(lifecycle: EngineLifecycle.stopped);
  Process? _process;
  RpcConnectionConfig? _localRpc;
  EngineConfig? _activeConfig;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  bool _intentionalStop = false;
  final List<String> _recentLogs = [];

  /// Recent stdout/stderr lines (capped).
  List<String> get recentLogs => List.unmodifiable(_recentLogs);

  /// Live log stream of engine stdout/stderr lines.
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

    // Prefer graceful RPC shutdown (aria2.shutdown), Motrix-style soft stop.
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

  /// Drop HTTP(S)_PROXY for the child so local RPC is never proxied.
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
