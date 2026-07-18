/// 启动本地 aria2-next / aria2c 进程时的参数。
///
/// 由 [ProcessEngineHost] 转成 CLI args；不负责找二进制路径。
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

  /// `--dir=`
  final String downloadDir;

  /// session 文件路径：既 `--save-session` 也可选 `--input-file`。
  final String sessionPath;

  /// `--rpc-listen-port=`
  final int rpcPort;

  /// `--rpc-secret=`（空则不传，允许无密钥的本机 aria2）。
  final String? rpcSecret;

  /// 可选 `--conf-path=`。
  final String? confPath;

  /// 追加在末尾的任意 CLI 参数。
  final List<String> extraArgs;

  final int maxConcurrentDownloads;
  final bool continueDownload;
  final bool enableRpc;

  /// false = 只监听本机（更安全，默认）。
  final bool rpcListenAll;

  /// 浏览器跨域调 RPC 时需要；本地 App 一般 true。
  final bool rpcAllowOriginAll;

  /// 生成进程参数列表。
  ///
  /// [sessionFileExists] 为 false 时不传 `--input-file`，避免 aria2 读空文件报错。
  /// 标志风格对齐 Motrix Next sidecar（`--enable-rpc=true` 等）。
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
