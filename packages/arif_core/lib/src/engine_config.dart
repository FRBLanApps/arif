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

  /// CLI args for `aria2-next` process mode.
  List<String> toProcessArgs() {
    return [
      if (enableRpc) '--enable-rpc',
      '--rpc-listen-all=${rpcListenAll ? 'true' : 'false'}',
      '--rpc-listen-port=$rpcPort',
      if (rpcSecret != null && rpcSecret!.isNotEmpty)
        '--rpc-secret=$rpcSecret',
      if (rpcAllowOriginAll) '--rpc-allow-origin-all',
      '--dir=$downloadDir',
      '--save-session=$sessionPath',
      if (continueDownload) '--continue=true',
      '--max-concurrent-downloads=$maxConcurrentDownloads',
      '--input-file=$sessionPath',
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
