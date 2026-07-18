import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_engine/arif_engine.dart';
import 'package:arif_rpc/arif_rpc.dart';

enum SessionPhase {
  disconnected,
  connecting,
  connected,
  error,
}

/// Manages a remote/local aria2 JSON-RPC session and polls task state.
///
/// Local profiles may start a process sidecar via [LocalEngineService]
/// (Motrix Next–style). Remote profiles only connect to an existing RPC.
class SessionController extends ChangeNotifier {
  SessionController({
    ConnectionProfile? profile,
    Duration pollInterval = const Duration(seconds: 1),
    Aria2Client? client,
    LocalEngineService? engineService,
    this.autoStartLocalEngine = true,
  })  : _profile = profile ?? ConnectionProfile.localDefault(),
        _pollInterval = pollInterval,
        _injectedClient = client,
        _engine = engineService ?? LocalEngineService(),
        _ownsEngine = engineService == null;

  final Aria2Client? _injectedClient;
  final Duration _pollInterval;
  final LocalEngineService _engine;
  final bool _ownsEngine;

  /// When true and profile is local, try spawn/reuse engine before RPC connect.
  final bool autoStartLocalEngine;

  ConnectionProfile _profile;
  Aria2Client? _client;
  Timer? _timer;
  SessionPhase _phase = SessionPhase.disconnected;
  String? _errorMessage;
  String? _engineVersion;
  GlobalStat? _globalStat;
  List<DownloadTask> _active = const [];
  List<DownloadTask> _waiting = const [];
  List<DownloadTask> _stopped = const [];
  TaskFilter _filter = TaskFilter.active;
  bool _disposed = false;
  int _pollGeneration = 0;
  bool _startedLocalEngine = false;

  ConnectionProfile get profile => _profile;
  SessionPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  String? get engineVersion => _engineVersion;
  GlobalStat? get globalStat => _globalStat;
  TaskFilter get filter => _filter;
  bool get isConnected => _phase == SessionPhase.connected;
  Aria2Client? get client => _client;
  LocalEngineService get engine => _engine;
  bool get localEngineRunning => _engine.status.isRunning;
  String? get localEngineBinary => _engine.resolvedBinary;

  List<DownloadTask> get activeTasks => _active;
  List<DownloadTask> get waitingTasks => _waiting;
  List<DownloadTask> get stoppedTasks => _stopped;

  List<DownloadTask> get visibleTasks {
    switch (_filter) {
      case TaskFilter.active:
        return _active;
      case TaskFilter.waiting:
        return _waiting;
      case TaskFilter.stopped:
        return _stopped;
      case TaskFilter.all:
        return [..._active, ..._waiting, ..._stopped];
    }
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<void> updateProfile(
    ConnectionProfile profile, {
    bool reconnect = true,
  }) async {
    _profile = profile;
    notifyListeners();
    if (reconnect) {
      await connect();
    }
  }

  Future<void> connect() async {
    await disconnect(notify: false, stopLocalEngine: false);
    _phase = SessionPhase.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      var rpc = _profile.rpc;

      if (_profile.isLocal &&
          autoStartLocalEngine &&
          _injectedClient == null) {
        final ensured = await _engine.ensureRunning(
          reuseExistingRpc: true,
          rpcPort: rpc.port,
          secret: rpc.secret,
        );
        rpc = ensured;
        _startedLocalEngine = _engine.host != null;
        // Keep profile RPC in sync if port was reallocated.
        if (rpc.port != _profile.rpc.port ||
            rpc.secret != _profile.rpc.secret) {
          _profile = _profile.copyWith(rpc: rpc);
        }
      }

      final client = _injectedClient ?? Aria2Client(config: rpc);
      _client = client;

      final version =
          await client.getVersion().timeout(const Duration(seconds: 5));
      _engineVersion = version.version;
      _phase = SessionPhase.connected;
      _errorMessage = null;
      notifyListeners();
      await refresh();
      _startPolling();
    } catch (e) {
      _phase = SessionPhase.error;
      _errorMessage = e is Aria2Exception ? e.message : e.toString();
      _engineVersion = null;
      if (_injectedClient == null) {
        _client?.close();
      }
      _client = null;
      notifyListeners();
    }
  }

  Future<void> disconnect({
    bool notify = true,
    bool stopLocalEngine = true,
  }) async {
    _stopPolling();
    _pollGeneration++;
    if (_injectedClient == null) {
      _client?.close();
    }
    _client = null;
    _phase = SessionPhase.disconnected;
    _errorMessage = null;
    _engineVersion = null;
    _globalStat = null;
    _active = const [];
    _waiting = const [];
    _stopped = const [];

    if (stopLocalEngine && _startedLocalEngine) {
      await _engine.stop();
      _startedLocalEngine = false;
    }

    if (notify && !_disposed) notifyListeners();
  }

  void _startPolling() {
    _stopPolling();
    _timer = Timer.periodic(_pollInterval, (_) {
      unawaited(refresh());
    });
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    final client = _client;
    if (client == null || _phase != SessionPhase.connected) return;

    final gen = _pollGeneration;
    try {
      final results = await Future.wait([
        client.getGlobalStat(),
        client.tellActive(),
        client.tellWaiting(0, 1000),
        client.tellStopped(0, 1000),
      ]);
      if (_disposed || gen != _pollGeneration) return;

      _globalStat = results[0] as GlobalStat;
      _active = results[1] as List<DownloadTask>;
      _waiting = results[2] as List<DownloadTask>;
      _stopped = results[3] as List<DownloadTask>;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (_disposed || gen != _pollGeneration) return;
      _phase = SessionPhase.error;
      _errorMessage = e is Aria2Exception ? e.message : e.toString();
      _stopPolling();
      notifyListeners();
    }
  }

  Future<String> addUri(String uri, {Map<String, String>? options}) async {
    final client = _requireClient();
    final lines = uri
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      throw Aria2Exception(message: 'Empty URI');
    }
    final gid = await client.addUri(lines, options: options);
    await refresh();
    return gid;
  }

  Future<void> pause(String gid) async {
    await _requireClient().pause(gid);
    await refresh();
  }

  Future<void> unpause(String gid) async {
    await _requireClient().unpause(gid);
    await refresh();
  }

  Future<void> remove(String gid) async {
    final client = _requireClient();
    DownloadTask? task;
    for (final t in [..._active, ..._waiting, ..._stopped]) {
      if (t.gid == gid) {
        task = t;
        break;
      }
    }
    final status = task?.status;
    if (status == 'complete' || status == 'error' || status == 'removed') {
      await client.removeDownloadResult(gid);
    } else {
      try {
        await client.remove(gid);
      } on Aria2Exception {
        await client.forceRemove(gid);
      }
      try {
        await client.removeDownloadResult(gid);
      } on Aria2Exception {
        // Result may already be gone.
      }
    }
    await refresh();
  }

  Aria2Client _requireClient() {
    final client = _client;
    if (client == null || _phase != SessionPhase.connected) {
      throw Aria2Exception(message: 'Not connected to aria2');
    }
    return client;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    if (_injectedClient == null) {
      _client?.close();
    }
    if (_ownsEngine) {
      unawaited(_engine.dispose());
    }
    super.dispose();
  }
}
