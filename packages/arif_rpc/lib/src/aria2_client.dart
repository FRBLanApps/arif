import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'aria2_exception.dart';
import 'aria2_models.dart';
import 'connection_config.dart';

/// aria2 / aria2-next 的 JSON-RPC 2.0 客户端（仅 HTTP POST）。
///
/// - 方法名带 `aria2.` 前缀，与官方手册一致
/// - [call] 自动在 params 前插入 `token:secret`（若配置了 secret）
/// - 数值字段在引擎侧多为字符串，模型层负责解析
///
/// UI 层建议经 SessionController 使用，便于轮询与生命周期统一。
class Aria2Client {
  Aria2Client({
    required this.config,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  /// 当前端点；引擎换端口后可改此字段或新建 Client。
  RpcConnectionConfig config;
  final http.Client _http;

  /// JSON-RPC id 递增，仅用于匹配响应。
  int _id = 0;

  Future<VersionInfo> getVersion() async {
    final result = await call('aria2.getVersion');
    return VersionInfo.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<GlobalStat> getGlobalStat() async {
    final result = await call('aria2.getGlobalStat');
    return GlobalStat.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<List<DownloadTask>> tellActive([List<String>? keys]) async {
    final result = await call(
      'aria2.tellActive',
      keys == null ? const [] : [keys],
    );
    return _mapTaskList(result);
  }

  Future<List<DownloadTask>> tellWaiting(
    int offset,
    int num, [
    List<String>? keys,
  ]) async {
    final params = <Object?>[offset, num];
    if (keys != null) params.add(keys);
    final result = await call('aria2.tellWaiting', params);
    return _mapTaskList(result);
  }

  Future<List<DownloadTask>> tellStopped(
    int offset,
    int num, [
    List<String>? keys,
  ]) async {
    final params = <Object?>[offset, num];
    if (keys != null) params.add(keys);
    final result = await call('aria2.tellStopped', params);
    return _mapTaskList(result);
  }

  Future<DownloadTask> tellStatus(String gid, [List<String>? keys]) async {
    final params = <Object?>[gid];
    if (keys != null) params.add(keys);
    final result = await call('aria2.tellStatus', params);
    return DownloadTask.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<String> addUri(
    List<String> uris, {
    Map<String, String>? options,
    int? position,
  }) async {
    final params = <Object?>[uris];
    if (options != null) params.add(options);
    if (position != null) {
      if (options == null) params.add(<String, String>{});
      params.add(position);
    }
    final result = await call('aria2.addUri', params);
    return result as String;
  }

  Future<String> addTorrent(
    String torrentBase64, {
    List<String> uris = const [],
    Map<String, String>? options,
    int? position,
  }) async {
    final params = <Object?>[torrentBase64, uris];
    if (options != null) params.add(options);
    if (position != null) {
      if (options == null) params.add(<String, String>{});
      params.add(position);
    }
    final result = await call('aria2.addTorrent', params);
    return result as String;
  }

  Future<String> pause(String gid) async {
    final result = await call('aria2.pause', [gid]);
    return result as String;
  }

  Future<String> forcePause(String gid) async {
    final result = await call('aria2.forcePause', [gid]);
    return result as String;
  }

  Future<String> unpause(String gid) async {
    final result = await call('aria2.unpause', [gid]);
    return result as String;
  }

  Future<String> remove(String gid) async {
    final result = await call('aria2.remove', [gid]);
    return result as String;
  }

  Future<String> forceRemove(String gid) async {
    final result = await call('aria2.forceRemove', [gid]);
    return result as String;
  }

  Future<String> pauseAll() async {
    final result = await call('aria2.pauseAll');
    return result as String;
  }

  Future<String> unpauseAll() async {
    final result = await call('aria2.unpauseAll');
    return result as String;
  }

  Future<String> forcePauseAll() async {
    final result = await call('aria2.forcePauseAll');
    return result as String;
  }

  Future<Map<String, String>> getOption(String gid) async {
    final result = await call('aria2.getOption', [gid]);
    return Map<String, String>.from(
      (result as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  Future<String> changeOption(String gid, Map<String, String> options) async {
    final result = await call('aria2.changeOption', [gid, options]);
    return result as String;
  }

  Future<List<DownloadFile>> getFiles(String gid) async {
    final result = await call('aria2.getFiles', [gid]);
    if (result is! List) return const [];
    return result
        .whereType<Map>()
        .map((e) => DownloadFile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, String>> getGlobalOption() async {
    final result = await call('aria2.getGlobalOption');
    return Map<String, String>.from(
      (result as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  Future<String> changeGlobalOption(Map<String, String> options) async {
    final result = await call('aria2.changeGlobalOption', [options]);
    return result as String;
  }

  Future<String> removeDownloadResult(String gid) async {
    final result = await call('aria2.removeDownloadResult', [gid]);
    return result as String;
  }

  Future<String> purgeDownloadResult() async {
    final result = await call('aria2.purgeDownloadResult');
    return result as String;
  }

  Future<String> saveSession() async {
    final result = await call('aria2.saveSession');
    return result as String;
  }

  /// 底层 JSON-RPC 调用。
  ///
  /// [method] 完整方法名，例如 `aria2.addUri`。
  /// [params] **不要**自己带 token；有 secret 时会自动插在列表最前。
  Future<Object?> call(String method, [List<Object?> params = const []]) async {
    final id = ++_id;
    // aria2 认证：params[0] = "token:<secret>"
    final finalParams = <Object?>[
      if (config.secret != null && config.secret!.isNotEmpty)
        'token:${config.secret}',
      ...params,
    ];

    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': finalParams,
    });

    late final http.Response response;
    try {
      response = await _http
          .post(
            config.httpUri,
            headers: const {
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Aria2Exception(message: 'RPC timeout talking to ${config.httpUri}');
    } on http.ClientException catch (e) {
      throw Aria2Exception(message: 'RPC transport error: ${e.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Aria2Exception(
        code: response.statusCode,
        message: 'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Aria2Exception(message: 'Invalid JSON-RPC response');
    }

    final map = Map<String, dynamic>.from(decoded);
    // JSON-RPC 错误对象：{ code, message, data? }
    if (map['error'] != null) {
      final err = Map<String, dynamic>.from(map['error'] as Map);
      throw Aria2Exception(
        code: err['code'] is int
            ? err['code'] as int
            : int.tryParse('${err['code']}'),
        message: err['message']?.toString() ?? 'Unknown RPC error',
        data: err['data'],
      );
    }

    return map['result'];
  }

  List<DownloadTask> _mapTaskList(Object? result) {
    if (result is! List) return const [];
    return result
        .whereType<Map>()
        .map((e) => DownloadTask.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void close() {
    _http.close();
  }
}
