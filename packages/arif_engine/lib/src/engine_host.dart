import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

import 'engine_status.dart';

/// Host for a local aria2-next instance.
///
/// - Desktop / Android V1: [ProcessEngineHost] (sidecar binary + RPC)
/// - iOS: FFI-backed implementation (later); process spawn is not used
abstract class EngineHost {
  Stream<EngineStatus> get status;

  EngineStatus get currentStatus;

  /// Local RPC endpoint after a successful [start], if applicable.
  RpcConnectionConfig? get localRpc;

  Future<void> start(EngineConfig config);

  Future<void> stop();

  Future<void> dispose();
}
