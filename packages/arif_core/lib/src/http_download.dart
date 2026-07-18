/// Options for a single HTTP(S)/FTP-style `aria2.addUri` task.
///
/// Maps to aria2 option keys used by Motrix Next / AriaNg for basic downloads.
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

  /// Download directory (`dir`).
  final String? dir;

  /// Output file name (`out`).
  final String? out;

  /// Number of connections per download (`split`).
  final int split;

  /// Max connections to one server (`max-connection-per-server`).
  final int maxConnectionPerServer;

  final String? referer;
  final String? userAgent;

  /// Extra HTTP headers as `Header: value` lines.
  final List<String> headers;

  final bool continueDownload;
  final int? maxTries;
  final int? timeout;

  /// Additional raw aria2 options (override same keys if present).
  final Map<String, String> extra;

  /// aria2 option map for JSON-RPC.
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

    // aria2 accepts multiple `header` via repeated keys in some UIs;
    // JSON-RPC uses a single string with newlines for multiple headers.
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

/// One or more HTTP(S) URIs to download (mirrors share one task when [asMirrors]).
class HttpDownloadRequest {
  const HttpDownloadRequest({
    required this.uris,
    this.options = const HttpDownloadOptions(),
    this.asMirrors = false,
  });

  final List<String> uris;
  final HttpDownloadOptions options;

  /// When true, all URIs go into a single addUri as mirrors.
  /// When false (default), each URI becomes its own task (Motrix-style multi-line).
  final bool asMirrors;

  bool get isEmpty => uris.isEmpty;
}

/// Parse multi-line / whitespace-separated URI input into a clean list.
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

/// Basic HTTP(S)/FTP scheme check for UI validation.
bool isSupportedHttpUri(String uri) {
  final lower = uri.toLowerCase();
  return lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('ftp://') ||
      lower.startsWith('ftps://');
}

/// Guess a filename from a URL path (for optional `out` default).
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
