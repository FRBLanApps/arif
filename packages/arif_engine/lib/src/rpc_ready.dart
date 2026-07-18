import 'dart:async';

import 'package:arif_rpc/arif_rpc.dart';

/// 轮询 [config] 直到 `aria2.getVersion` 成功，或超时。
///
/// 进程刚 spawn 时 RPC 尚未监听，需要短暂重试（Motrix / 多数 sidecar 同理）。
Future<VersionInfo> waitForRpcReady(
  RpcConnectionConfig config, {
  Duration timeout = const Duration(seconds: 15),
  Duration interval = const Duration(milliseconds: 200),
  Aria2Client? client,
}) async {
  final ownsClient = client == null;
  final c = client ?? Aria2Client(config: config);
  final deadline = DateTime.now().add(timeout);
  Object? lastError;

  try {
    while (DateTime.now().isBefore(deadline)) {
      try {
        return await c.getVersion().timeout(const Duration(seconds: 2));
      } catch (e) {
        lastError = e;
        await Future<void>.delayed(interval);
      }
    }
    throw TimeoutException(
      'RPC not ready at ${config.httpUri}: $lastError',
      timeout,
    );
  } finally {
    if (ownsClient) {
      c.close();
    }
  }
}
