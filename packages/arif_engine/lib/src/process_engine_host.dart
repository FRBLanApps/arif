import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';
import 'package:path/path.dart' as p;

import 'engine_host.dart';
import 'engine_status.dart';

/// Spawns `aria2-next` as a child process and exposes loopback RPC.
///
/// Used on Linux, Windows, and Android (with a pre-staged binary).
/// Not used on iOS (see FFI host + keep-alive docs).
class ProcessEngineHost implements EngineHost {
  ProcessEngineHost({
    required this.executablePath,
    this.workingDirectory,
  });

  /// Absolute path to the aria2-next binary.
  final String executablePath;

  final String? workingDirectory;

  final _statusController = StreamController<EngineStatus>.broadcast();
  EngineStatus _status = const EngineStatus(lifecycle: EngineLifecycle.stopped);
  Process? _process;
  RpcConnectionConfig? _localRpc;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;

  @override
  Stream<EngineStatus> get status => _statusController.stream;

  @override
  EngineStatus get currentStatus => _status;

  @override
  RpcConnectionConfig? get localRpc => _localRpc;

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

    await Directory(config.downloadDir).create(recursive: true);
    await Directory(p.dirname(config.sessionPath)).create(recursive: true);
    final sessionFile = File(config.sessionPath);
    if (!await sessionFile.exists()) {
      await sessionFile.create(recursive: true);
    }

    _emit(
      EngineStatus(
        lifecycle: EngineLifecycle.starting,
        rpcPort: config.rpcPort,
      ),
    );

    final args = config.toProcessArgs();
    _process = await Process.start(
      executablePath,
      args,
      workingDirectory: workingDirectory,
      mode: ProcessStartMode.normal,
    );

    _stdoutSub = _process!.stdout
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((_) {});
    _stderrSub = _process!.stderr
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter())
        .listen((_) {});

    _process!.exitCode.then((code) {
      if (_status.lifecycle == EngineLifecycle.stopping ||
          _status.lifecycle == EngineLifecycle.stopped) {
        return;
      }
      _emit(
        EngineStatus(
          lifecycle: EngineLifecycle.crashed,
          message: 'Engine exited with code $code',
          pid: _process?.pid,
          rpcPort: config.rpcPort,
        ),
      );
      _process = null;
    });

    _localRpc = RpcConnectionConfig(
      host: '127.0.0.1',
      port: config.rpcPort,
      secret: config.rpcSecret,
    );

    _emit(
      EngineStatus(
        lifecycle: EngineLifecycle.running,
        pid: _process!.pid,
        rpcPort: config.rpcPort,
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

    _emit(
      EngineStatus(
        lifecycle: EngineLifecycle.stopping,
        pid: process.pid,
        rpcPort: _status.rpcPort,
      ),
    );

    process.kill(ProcessSignal.sigterm);
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }

    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _process = null;
    _localRpc = null;
    _emit(const EngineStatus(lifecycle: EngineLifecycle.stopped));
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _statusController.close();
  }

  void _emit(EngineStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
