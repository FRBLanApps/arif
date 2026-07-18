/// RPC 传输方式。V1 实际只用 [http]；WebSocket 预留（通知推送以后再接）。
enum RpcTransport {
  http,
  webSocket,
}

/// 如何连上 aria2 / aria2-next 的 JSON-RPC。
///
/// 本地引擎与远程 NAS 共用同一结构；[secret] 会在请求 params 最前面
/// 注入为 `token:xxx`（aria2 约定）。
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

  /// RPC 密钥；null/空表示不启用 token 认证。
  final String? secret;

  /// true 时用 https/wss。
  final bool useTls;

  /// 默认 aria2 路径 `/jsonrpc`。
  final String rpcPath;

  final RpcTransport transport;

  /// HTTP POST 用的完整 URI。
  Uri get httpUri {
    final scheme = useTls ? 'https' : 'http';
    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: rpcPath,
    );
  }

  /// WebSocket 用的 URI（尚未在客户端实现）。
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
    bool clearSecret = false,
    bool? useTls,
    String? rpcPath,
    RpcTransport? transport,
  }) {
    return RpcConnectionConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      // clearSecret 才能把 secret 显式清成 null
      secret: clearSecret ? null : (secret ?? this.secret),
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
