/// Runtime options for starting a local aria2-next engine.
class EngineConfig {
  const EngineConfig({
    required this.downloadDir,
    required this.sessionPath,
    required this.rpcPort,
    this.rpcSecret,
    this.confPath,
    this.extraArgs = const [],
    this.maxConcurrentDownloads = 5,
    this.continueDownload = true,
    this.enableRpc = true,
    this.rpcListenAll = false,
    this.rpcAllowOriginAll = true,
  });

  final String downloadDir;
  final String sessionPath;
  final int rpcPort;
  final String? rpcSecret;
  final String? confPath;
  final List<String> extraArgs;
  final int maxConcurrentDownloads;
  final bool continueDownload;
  final bool enableRpc;
  final bool rpcListenAll;
  final bool rpcAllowOriginAll;

  /// CLI args for `aria2-next` / `aria2c` process mode.
  ///
  /// Mirrors Motrix Next sidecar flags: enable RPC, loopback by default,
  /// session restore when the session file exists.
  List<String> toProcessArgs({bool sessionFileExists = true}) {
    return [
      if (enableRpc) ...[
        '--enable-rpc=true',
        '--rpc-listen-all=${rpcListenAll ? 'true' : 'false'}',
        '--rpc-listen-port=$rpcPort',
        if (rpcAllowOriginAll) '--rpc-allow-origin-all=true',
        if (rpcSecret != null && rpcSecret!.isNotEmpty)
          '--rpc-secret=$rpcSecret',
      ],
      '--dir=$downloadDir',
      '--save-session=$sessionPath',
      '--save-session-interval=30',
      if (sessionFileExists) '--input-file=$sessionPath',
      if (continueDownload) '--continue=true',
      '--max-concurrent-downloads=$maxConcurrentDownloads',
      if (confPath != null) '--conf-path=$confPath',
      ...extraArgs,
    ];
  }


  EngineConfig copyWith({
    String? downloadDir,
    String? sessionPath,
    int? rpcPort,
    String? rpcSecret,
    String? confPath,
    List<String>? extraArgs,
    int? maxConcurrentDownloads,
    bool? continueDownload,
    bool? enableRpc,
    bool? rpcListenAll,
    bool? rpcAllowOriginAll,
  }) {
    return EngineConfig(
      downloadDir: downloadDir ?? this.downloadDir,
      sessionPath: sessionPath ?? this.sessionPath,
      rpcPort: rpcPort ?? this.rpcPort,
      rpcSecret: rpcSecret ?? this.rpcSecret,
      confPath: confPath ?? this.confPath,
      extraArgs: extraArgs ?? this.extraArgs,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      continueDownload: continueDownload ?? this.continueDownload,
      enableRpc: enableRpc ?? this.enableRpc,
      rpcListenAll: rpcListenAll ?? this.rpcListenAll,
      rpcAllowOriginAll: rpcAllowOriginAll ?? this.rpcAllowOriginAll,
    );
  }
}
