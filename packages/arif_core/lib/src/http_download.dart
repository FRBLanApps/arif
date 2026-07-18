// HTTP(S)/FTP 下载的领域模型与工具。
// UI / Session 构造 HttpDownloadRequest，再 toAria2Options 交给 aria2.addUri。
// 设计参考 Motrix Next 的 AddTask 表单字段。

/// 单次 `aria2.addUri` 的下载选项。
///
/// 字段名与 aria2 配置键对应，见各成员注释。
class HttpDownloadOptions {
  const HttpDownloadOptions({
    this.dir,
    this.out,
    this.split = 16,
    this.maxConnectionPerServer = 16,
    this.referer,
    this.userAgent,
    this.headers = const [],
    this.continueDownload = true,
    this.maxTries,
    this.timeout,
    this.extra = const {},
  });

  /// 保存目录，对应 aria2 `dir`。
  final String? dir;

  /// 输出文件名，对应 `out`（不含路径）。
  final String? out;

  /// 分片连接数，对应 `split`。
  final int split;

  /// 对同一服务器的最大连接数，对应 `max-connection-per-server`。
  final int maxConnectionPerServer;

  /// HTTP Referer。
  final String? referer;

  /// User-Agent。
  final String? userAgent;

  /// 额外 HTTP 头，每项形如 `Header-Name: value`。
  final List<String> headers;

  /// 是否断点续传（`continue=true`）。
  final bool continueDownload;

  /// 最大重试次数（`max-tries`）。
  final int? maxTries;

  /// 超时秒数（`timeout`）。
  final int? timeout;

  /// 额外原始 aria2 选项；同名键会覆盖上面已生成的项。
  final Map<String, String> extra;

  /// 转为 JSON-RPC 可用的 `Map<optionName, value>`。
  Map<String, String> toAria2Options() {
    final map = <String, String>{
      if (dir != null && dir!.trim().isNotEmpty) 'dir': dir!.trim(),
      if (out != null && out!.trim().isNotEmpty) 'out': out!.trim(),
      'split': '$split',
      'max-connection-per-server': '$maxConnectionPerServer',
      if (referer != null && referer!.trim().isNotEmpty)
        'referer': referer!.trim(),
      if (userAgent != null && userAgent!.trim().isNotEmpty)
        'user-agent': userAgent!.trim(),
      if (continueDownload) 'continue': 'true',
      if (maxTries != null) 'max-tries': '$maxTries',
      if (timeout != null) 'timeout': '$timeout',
      ...extra,
    };

    // JSON-RPC 里多个 header 用换行拼进同一个 `header` 字符串。
    if (headers.isNotEmpty) {
      final cleaned = headers
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (cleaned.isNotEmpty) {
        map['header'] = cleaned.join('\n');
      }
    }
    return map;
  }

  HttpDownloadOptions copyWith({
    String? dir,
    String? out,
    int? split,
    int? maxConnectionPerServer,
    String? referer,
    String? userAgent,
    List<String>? headers,
    bool? continueDownload,
    int? maxTries,
    int? timeout,
    Map<String, String>? extra,
  }) {
    return HttpDownloadOptions(
      dir: dir ?? this.dir,
      out: out ?? this.out,
      split: split ?? this.split,
      maxConnectionPerServer:
          maxConnectionPerServer ?? this.maxConnectionPerServer,
      referer: referer ?? this.referer,
      userAgent: userAgent ?? this.userAgent,
      headers: headers ?? this.headers,
      continueDownload: continueDownload ?? this.continueDownload,
      maxTries: maxTries ?? this.maxTries,
      timeout: timeout ?? this.timeout,
      extra: extra ?? this.extra,
    );
  }
}

/// 一次「添加 HTTP 下载」请求：URI 列表 + 选项 + 是否镜像。
class HttpDownloadRequest {
  const HttpDownloadRequest({
    required this.uris,
    this.options = const HttpDownloadOptions(),
    this.asMirrors = false,
  });

  final List<String> uris;
  final HttpDownloadOptions options;

  /// true：全部 URI 作为同一文件的镜像（一次 addUri，一个 GID）。
  /// false：每行 URI 各自一个任务（Motrix 多行默认行为）。
  final bool asMirrors;

  bool get isEmpty => uris.isEmpty;
}

/// 把多行/空白分隔的输入解析成去重后的 URI 列表（保持首次出现顺序）。
List<String> parseUriList(String raw) {
  final lines = raw
      .split(RegExp(r'[\r\n]+'))
      .expand((line) => line.split(RegExp(r'\s+')))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final seen = <String>{};
  final result = <String>[];
  for (final uri in lines) {
    if (seen.add(uri)) result.add(uri);
  }
  return result;
}

/// UI 层校验：当前 V1 只接受 http(s)/ftp(s)。磁力/BT 后续再开。
bool isSupportedHttpUri(String uri) {
  final lower = uri.toLowerCase();
  return lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('ftp://') ||
      lower.startsWith('ftps://');
}

/// 从 URL path 猜文件名（供可选默认 `out`）。
String? guessFilenameFromUri(String uri) {
  try {
    final parsed = Uri.parse(uri);
    if (parsed.pathSegments.isEmpty) return null;
    final last = parsed.pathSegments.last;
    if (last.isEmpty) return null;
    return Uri.decodeComponent(last);
  } catch (_) {
    return null;
  }
}
