/// How the client reaches an aria2 / aria2-next instance.
enum RpcTransport {
  http,
  webSocket,
}

/// Endpoint and auth for JSON-RPC.
class RpcConnectionConfig {
  const RpcConnectionConfig({
    required this.host,
    this.port = 6800,
    this.secret,
    this.useTls = false,
    this.rpcPath = '/jsonrpc',
    this.transport = RpcTransport.http,
  });

  final String host;
  final int port;
  final String? secret;
  final bool useTls;
  final String rpcPath;
  final RpcTransport transport;

  Uri get httpUri {
    final scheme = useTls ? 'https' : 'http';
    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: rpcPath,
    );
  }

  Uri get webSocketUri {
    final scheme = useTls ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: rpcPath,
    );
  }

  RpcConnectionConfig copyWith({
    String? host,
    int? port,
    String? secret,
    bool? useTls,
    String? rpcPath,
    RpcTransport? transport,
  }) {
    return RpcConnectionConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      secret: secret ?? this.secret,
      useTls: useTls ?? this.useTls,
      rpcPath: rpcPath ?? this.rpcPath,
      transport: transport ?? this.transport,
    );
  }

  Map<String, Object?> toJson() => {
        'host': host,
        'port': port,
        'secret': secret,
        'useTls': useTls,
        'rpcPath': rpcPath,
        'transport': transport.name,
      };

  factory RpcConnectionConfig.fromJson(Map<String, Object?> json) {
    return RpcConnectionConfig(
      host: json['host'] as String? ?? '127.0.0.1',
      port: json['port'] as int? ?? 6800,
      secret: json['secret'] as String?,
      useTls: json['useTls'] as bool? ?? false,
      rpcPath: json['rpcPath'] as String? ?? '/jsonrpc',
      transport: RpcTransport.values.firstWhere(
        (e) => e.name == json['transport'],
        orElse: () => RpcTransport.http,
      ),
    );
  }
}
