import 'package:arif_rpc/arif_rpc.dart';

/// Whether the app talks to a bundled local engine or a remote instance.
enum EngineMode {
  /// Spawn / embed local aria2-next, then RPC to localhost.
  local,

  /// Only connect to an existing RPC endpoint.
  remote,
}

/// User-facing connection profile (local engine or remote RPC).
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

  /// Default local engine profile (loopback RPC).
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
