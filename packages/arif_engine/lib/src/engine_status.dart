/// 本地引擎生命周期状态机。
enum EngineLifecycle {
  stopped,
  starting,
  running,
  stopping,
  /// 进程异常退出或启动失败。
  crashed,
  /// 当前平台不支持该 Host 实现（如 iOS 上的 ProcessEngineHost）。
  unsupported,
}

/// [EngineHost] 对外暴露的状态快照。
class EngineStatus {
  const EngineStatus({
    required this.lifecycle,
    this.message,
    this.pid,
    this.rpcPort,
  });

  final EngineLifecycle lifecycle;

  /// 人类可读说明（崩溃原因等）。
  final String? message;

  final int? pid;
  final int? rpcPort;

  bool get isRunning => lifecycle == EngineLifecycle.running;

  EngineStatus copyWith({
    EngineLifecycle? lifecycle,
    String? message,
    int? pid,
    int? rpcPort,
  }) {
    return EngineStatus(
      lifecycle: lifecycle ?? this.lifecycle,
      message: message ?? this.message,
      pid: pid ?? this.pid,
      rpcPort: rpcPort ?? this.rpcPort,
    );
  }
}
