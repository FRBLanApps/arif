import 'http_download.dart';

/// 应用级下载默认值（尚未做持久化；仅内存，重启丢失）。
///
/// 添加任务时若表单未填 dir/UA/split，会落到这里。
class AppDownloadSettings {
  const AppDownloadSettings({
    this.defaultDir,
    this.split = 16,
    this.maxConnectionPerServer = 16,
    this.userAgent,
    this.continueDownload = true,
  });

  /// 默认下载目录。
  final String? defaultDir;

  /// 默认 split。
  final int split;

  /// 默认 max-connection-per-server。
  final int maxConnectionPerServer;

  final String? userAgent;
  final bool continueDownload;

  /// 用当前默认值拼一份 [HttpDownloadOptions]，再可被单次请求覆盖。
  HttpDownloadOptions toHttpOptions({
    String? out,
    String? dir,
    String? referer,
    List<String> headers = const [],
  }) {
    return HttpDownloadOptions(
      dir: dir ?? defaultDir,
      out: out,
      split: split,
      maxConnectionPerServer: maxConnectionPerServer,
      referer: referer,
      userAgent: userAgent,
      headers: headers,
      continueDownload: continueDownload,
    );
  }

  AppDownloadSettings copyWith({
    String? defaultDir,
    int? split,
    int? maxConnectionPerServer,
    String? userAgent,
    bool? continueDownload,
  }) {
    return AppDownloadSettings(
      defaultDir: defaultDir ?? this.defaultDir,
      split: split ?? this.split,
      maxConnectionPerServer:
          maxConnectionPerServer ?? this.maxConnectionPerServer,
      userAgent: userAgent ?? this.userAgent,
      continueDownload: continueDownload ?? this.continueDownload,
    );
  }

  Map<String, Object?> toJson() => {
        'defaultDir': defaultDir,
        'split': split,
        'maxConnectionPerServer': maxConnectionPerServer,
        'userAgent': userAgent,
        'continueDownload': continueDownload,
      };

  factory AppDownloadSettings.fromJson(Map<String, Object?> json) {
    return AppDownloadSettings(
      defaultDir: json['defaultDir'] as String?,
      split: json['split'] as int? ?? 16,
      maxConnectionPerServer: json['maxConnectionPerServer'] as int? ?? 16,
      userAgent: json['userAgent'] as String?,
      continueDownload: json['continueDownload'] as bool? ?? true,
    );
  }
}
