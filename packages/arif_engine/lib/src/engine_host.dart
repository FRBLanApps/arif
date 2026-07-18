import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

import 'engine_status.dart';

/// 本地引擎宿主抽象。
///
/// - 桌面 / Android（V1）：[ProcessEngineHost] 子进程 + 回环 RPC
/// - iOS（以后）：FFI / libaria2，不 spawn 进程
///
/// 上层只关心 [start]/[stop] 与 [localRpc]，不要直接依赖进程实现。
abstract class EngineHost {
  Stream<EngineStatus> get status;

  EngineStatus get currentStatus;

  /// 成功 [start] 后的本机 RPC 配置；未运行时为 null。
  RpcConnectionConfig? get localRpc;

  Future<void> start(EngineConfig config);

  Future<void> stop();

  Future<void> dispose();
}
