import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_engine/arif_engine.dart';
import 'package:arif_rpc/arif_rpc.dart';

/// 会话连接阶段（驱动 Home 状态条 / 空状态页）。
enum SessionPhase {
  disconnected,
  connecting,
  connected,
  error,
}

/// App 侧「会话」中枢：连引擎、轮询任务、增删改下载。
///
/// ## 分层
/// ```
/// UI (Home / AddHttp / Connections)
///   → SessionController          // 本类
///     → LocalEngineService       // 仅 local 模式：复用或 spawn
///     → Aria2Client              // JSON-RPC
/// ```
///
/// ## 连接策略
/// - [EngineMode.local]：先 [LocalEngineService.ensureRunning]（可复用本机已有 aria2），
///   再 RPC；强制 host=127.0.0.1、无 TLS。
/// - [EngineMode.remote]：只连用户填的 host:port。
///
/// ## 并发注意
/// - [connect] 串行，避免连点两次起两个引擎。
/// - [_connectGeneration] / [_pollGeneration] 丢弃过期的异步结果。
/// - [refresh] 用 [_refreshInFlight] 防止 1s 定时器叠请求。
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

  /// 测试注入的 Client（跳过真实网络 / 本地引擎）。
  final Aria2Client? _injectedClient;
  final Duration _pollInterval;
  final LocalEngineService _engine;
  final bool _ownsEngine;

  /// local 模式下是否自动 ensureRunning。
  final bool autoStartLocalEngine;

  ConnectionProfile _profile;
  Aria2Client? _client;
  Timer? _timer;
  SessionPhase _phase = SessionPhase.disconnected;
  String? _errorMessage;
  String? _engineVersion;
  GlobalStat? _globalStat;

  /// 与 aria2 tell* 三列表对应（paused 在 waiting 里）。
  List<DownloadTask> _active = const [];
  List<DownloadTask> _waiting = const [];
  List<DownloadTask> _stopped = const [];

  TaskFilter _filter = TaskFilter.active;
  bool _disposed = false;

  /// 每次 disconnect / 新一轮 poll 递增，用于作废 in-flight 的 refresh。
  int _pollGeneration = 0;

  /// 每次 connect 递增，用于作废过期的 connect 异步步骤。
  int _connectGeneration = 0;

  /// 当前进行中的 connect Future（串行化入口）。
  Future<void>? _connectInFlight;

  bool _refreshInFlight = false;

  ConnectionProfile get profile => _profile;
  SessionPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  String? get engineVersion => _engineVersion;
  GlobalStat? get globalStat => _globalStat;
  TaskFilter get filter => _filter;
  bool get isConnected => _phase == SessionPhase.connected;
  bool get isConnecting => _phase == SessionPhase.connecting;
  Aria2Client? get client => _client;
  LocalEngineService get engine => _engine;

  /// 我们 spawn 的引擎是否在跑（复用外部 aria2 时为 false）。
  bool get localEngineRunning => _engine.isManagedRunning;
  String? get localEngineBinary => _engine.resolvedBinary;

  List<DownloadTask> get activeTasks => _active;
  List<DownloadTask> get waitingTasks => _waiting;
  List<DownloadTask> get stoppedTasks => _stopped;

  AppDownloadSettings _downloadSettings = const AppDownloadSettings();
  AppDownloadSettings get downloadSettings => _downloadSettings;

  void updateDownloadSettings(AppDownloadSettings settings) {
    _downloadSettings = settings;
    notifyListeners();
  }

  List<DownloadTask> get allTasks => [..._active, ..._waiting, ..._stopped];

  /// 当前 Tab 可见任务。
  ///
  /// 注意：直接使用 aria2 三列表，而不是再按 [TaskStatus.bucket] 过滤一遍，
  /// 这样与引擎侧分类一致（paused 在 waiting 列表）。
  List<DownloadTask> get visibleTasks {
    switch (_filter) {
      case TaskFilter.active:
        return _active;
      case TaskFilter.waiting:
        return _waiting;
      case TaskFilter.stopped:
        return _stopped;
      case TaskFilter.all:
        return allTasks;
    }
  }

  DownloadTask? findTask(String gid) {
    for (final t in allTasks) {
      if (t.gid == gid) return t;
    }
    return null;
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  /// 更新连接配置；[reconnect] 时会 [connect]。
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

  /// 建立会话（可重复调用；会串行、会取消过期结果）。
  Future<void> connect() async {
    if (_disposed) return;
    // 若已有 connect 在飞：等它结束；已连上则直接返回，避免双开引擎。
    final previous = _connectInFlight;
    if (previous != null) {
      await previous;
      if (_disposed || isConnected) return;
    }

    final op = _connectImpl();
    _connectInFlight = op;
    try {
      await op;
    } finally {
      if (identical(_connectInFlight, op)) {
        _connectInFlight = null;
      }
    }
  }

  Future<void> _connectImpl() async {
    final gen = ++_connectGeneration;

    // 拆掉旧 RPC。离开 local 或关闭 autoStart 时顺带停托管引擎。
    final stopEngine = !_profile.isLocal || !autoStartLocalEngine;
    await disconnect(notify: false, stopLocalEngine: stopEngine);
    if (_disposed || gen != _connectGeneration) return;

    // local 重连：先停旧托管进程，方便换端口/密钥后 ensureRunning。
    if (_profile.isLocal && autoStartLocalEngine) {
      await _engine.stop();
    }
    if (_disposed || gen != _connectGeneration) return;

    _phase = SessionPhase.connecting;
    _errorMessage = null;
    notifyListeners();

    var managedSpawnAttempted = false;

    try {
      var rpc = _profile.rpc;

      if (_profile.isLocal && autoStartLocalEngine && _injectedClient == null) {
        // 本地引擎只听回环。
        rpc = rpc.copyWith(host: '127.0.0.1', useTls: false);
        managedSpawnAttempted = true;
        final ensured = await _engine.ensureRunning(
          reuseExistingRpc: true,
          rpcPort: rpc.port,
          secret: rpc.secret,
        );
        if (_disposed || gen != _connectGeneration) {
          await _engine.stop();
          return;
        }
        // ensureRunning 可能因端口冲突换了 port。
        rpc = ensured;
        _profile = _profile.copyWith(
          rpc: rpc.copyWith(host: '127.0.0.1', useTls: false),
        );
      }

      final client = _injectedClient ?? Aria2Client(config: rpc);
      if (_disposed || gen != _connectGeneration) {
        if (_injectedClient == null) client.close();
        if (managedSpawnAttempted && _engine.isManagedRunning) {
          await _engine.stop();
        }
        return;
      }
      _client = client;

      final version =
          await client.getVersion().timeout(const Duration(seconds: 5));
      if (_disposed || gen != _connectGeneration) {
        if (_injectedClient == null) client.close();
        _client = null;
        return;
      }

      _engineVersion = version.version;
      _phase = SessionPhase.connected;
      _errorMessage = null;
      notifyListeners();
      await refresh();
      if (_disposed || gen != _connectGeneration) return;
      if (_phase == SessionPhase.connected) {
        _startPolling();
      }
    } catch (e) {
      if (_disposed || gen != _connectGeneration) return;

      // 连接失败不要留下我们拉起的孤儿进程。
      if (managedSpawnAttempted && _engine.isManagedRunning) {
        await _engine.stop();
      }

      _phase = SessionPhase.error;
      _errorMessage = e is Aria2Exception
          ? e.message
          : e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      _engineVersion = null;
      if (_injectedClient == null) {
        _client?.close();
      }
      _client = null;
      notifyListeners();
    }
  }

  /// 断开 RPC 轮询；[stopLocalEngine] 为 true 时停止我们托管的引擎进程。
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

    if (stopLocalEngine) {
      await _engine.stop();
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

  /// 拉取全局统计 + 三列表。失败会进入 [SessionPhase.error] 并停轮询。
  Future<void> refresh() async {
    final client = _client;
    if (client == null || _phase != SessionPhase.connected) return;
    if (_refreshInFlight) return;
    _refreshInFlight = true;

    final gen = _pollGeneration;
    try {
      final results = await Future.wait([
        client.getGlobalStat(),
        client.tellActive(),
        client.tellWaiting(0, 1000),
        client.tellStopped(0, 1000),
      ]);
      if (_disposed || gen != _pollGeneration) return;
      if (_phase != SessionPhase.connected) return;

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
    } finally {
      _refreshInFlight = false;
    }
  }

  /// 简便入口：把字符串当 URI 列表，按镜像合成一个任务。
  Future<String> addUri(String uri, {Map<String, String>? options}) async {
    final gids = await addHttpDownload(
      HttpDownloadRequest(
        uris: parseUriList(uri),
        options: HttpDownloadOptions(
          dir: options?['dir'] ?? _downloadSettings.defaultDir,
          out: options?['out'],
          split: int.tryParse(options?['split'] ?? '') ??
              _downloadSettings.split,
          maxConnectionPerServer: int.tryParse(
                options?['max-connection-per-server'] ?? '',
              ) ??
              _downloadSettings.maxConnectionPerServer,
          referer: options?['referer'],
          userAgent: options?['user-agent'] ?? _downloadSettings.userAgent,
        ),
        asMirrors: true,
      ),
    );
    return gids.first;
  }

  /// 添加 HTTP(S)/FTP 下载，返回新建 GID 列表。
  ///
  /// - [HttpDownloadRequest.asMirrors] 或仅 1 个 URI：一次 addUri
  /// - 否则每个 URI 一个任务；多任务时去掉共享的 `out`，避免重名覆盖
  Future<List<String>> addHttpDownload(HttpDownloadRequest request) async {
    final client = _requireClient();
    if (request.isEmpty) {
      throw Aria2Exception(message: 'Empty URI');
    }

    final unsupported = request.uris.where((u) => !isSupportedHttpUri(u));
    if (unsupported.isNotEmpty) {
      throw Aria2Exception(
        message: 'Unsupported URI scheme: ${unsupported.first}',
      );
    }

    // 表单未填的项用 App 默认值补齐。
    final base = _downloadSettings.toHttpOptions(
      dir: request.options.dir,
      out: request.options.out,
      referer: request.options.referer,
      headers: request.options.headers,
    );
    final opts = HttpDownloadOptions(
      dir: request.options.dir ?? base.dir,
      out: request.options.out,
      split: request.options.split,
      maxConnectionPerServer: request.options.maxConnectionPerServer,
      referer: request.options.referer,
      userAgent: request.options.userAgent ?? base.userAgent,
      headers: request.options.headers,
      continueDownload: request.options.continueDownload,
      maxTries: request.options.maxTries,
      timeout: request.options.timeout,
      extra: request.options.extra,
    ).toAria2Options();

    final gids = <String>[];
    if (request.asMirrors || request.uris.length == 1) {
      gids.add(await client.addUri(request.uris, options: opts));
    } else {
      for (final uri in request.uris) {
        final perOpts = Map<String, String>.from(opts);
        if (request.uris.length > 1) {
          perOpts.remove('out');
        }
        gids.add(await client.addUri([uri], options: perOpts));
      }
    }

    try {
      await client.saveSession();
    } on Aria2Exception {
      // 部分构建未开 session 时忽略。
    }
    await refresh();
    return gids;
  }

  Future<void> pause(String gid) async {
    await _requireClient().pause(gid);
    await refresh();
  }

  Future<void> unpause(String gid) async {
    await _requireClient().unpause(gid);
    await refresh();
  }

  Future<void> pauseAll() async {
    await _requireClient().pauseAll();
    await refresh();
  }

  Future<void> unpauseAll() async {
    await _requireClient().unpauseAll();
    await refresh();
  }

  /// 删除任务。
  ///
  /// 已结束任务用 [Aria2Client.removeDownloadResult]；
  /// 进行中用 remove / forceRemove。默认不立刻 purge，方便在 stopped 列表里再看到。
  Future<void> remove(String gid, {bool purgeResult = false}) async {
    final client = _requireClient();
    final task = findTask(gid);
    final status = task?.status;
    if (status == 'complete' || status == 'error' || status == 'removed') {
      await client.removeDownloadResult(gid);
    } else {
      try {
        await client.remove(gid);
      } on Aria2Exception {
        await client.forceRemove(gid);
      }
      if (purgeResult) {
        try {
          await client.removeDownloadResult(gid);
        } on Aria2Exception {
          // 结果可能已不存在。
        }
      }
    }
    try {
      await client.saveSession();
    } on Aria2Exception {
      // ignore
    }
    await refresh();
  }

  /// 清空已停止任务结果列表（purgeDownloadResult）。
  Future<void> purgeStopped() async {
    await _requireClient().purgeDownloadResult();
    await refresh();
  }

  Future<DownloadTask> fetchTask(String gid) async {
    return _requireClient().tellStatus(gid);
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
    _connectGeneration++;
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
