enum EngineLifecycle {
  stopped,
  starting,
  running,
  stopping,
  crashed,
  unsupported,
}

class EngineStatus {
  const EngineStatus({
    required this.lifecycle,
    this.message,
    this.pid,
    this.rpcPort,
  });

  final EngineLifecycle lifecycle;
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
