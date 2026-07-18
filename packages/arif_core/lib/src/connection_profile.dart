import 'package:arif_rpc/arif_rpc.dart';

/// 连接模式：本地托管引擎 vs 只连已有 RPC。
enum EngineMode {
  /// 本地：优先复用本机端口上的 aria2；没有则由 arif_engine 拉起进程。
  local,

  /// 远程：只连 host:port，不 spawn 引擎。
  remote,
}

/// 用户可见的「连接配置」：模式 + RPC 端点。
///
/// UI 存在 Connections 页；Session 连接时读 [mode] 决定是否 ensureRunning。
class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.mode,
    required this.rpc,
  });

  final String id;
  final String name;
  final EngineMode mode;

  /// JSON-RPC 地址（host/port/secret/TLS）。
  final RpcConnectionConfig rpc;

  bool get isLocal => mode == EngineMode.local;

  ConnectionProfile copyWith({
    String? id,
    String? name,
    EngineMode? mode,
    RpcConnectionConfig? rpc,
  }) {
    return ConnectionProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      rpc: rpc ?? this.rpc,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.name,
        'rpc': rpc.toJson(),
      };

  factory ConnectionProfile.fromJson(Map<String, Object?> json) {
    final rpcRaw = json['rpc'];
    return ConnectionProfile(
      id: json['id'] as String? ?? 'default',
      name: json['name'] as String? ?? 'Default',
      mode: EngineMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => EngineMode.local,
      ),
      rpc: rpcRaw is Map
          ? RpcConnectionConfig.fromJson(Map<String, Object?>.from(rpcRaw))
          : const RpcConnectionConfig(host: '127.0.0.1'),
    );
  }

  /// 默认本地配置：127.0.0.1:6800，无 secret。
  static ConnectionProfile localDefault({
    String id = 'local',
    int port = 6800,
    String? secret,
  }) {
    return ConnectionProfile(
      id: id,
      name: 'Local',
      mode: EngineMode.local,
      rpc: RpcConnectionConfig(
        host: '127.0.0.1',
        port: port,
        secret: secret,
      ),
    );
  }
}
