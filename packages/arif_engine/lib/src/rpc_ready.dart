import 'dart:async';

import 'package:arif_rpc/arif_rpc.dart';

/// Polls [config] until `aria2.getVersion` succeeds or [timeout] elapses.
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
