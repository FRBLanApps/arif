import 'http_download.dart';

/// Lightweight app-level download defaults (not full preference store yet).
class AppDownloadSettings {
  const AppDownloadSettings({
    this.defaultDir,
    this.split = 16,
    this.maxConnectionPerServer = 16,
    this.userAgent,
    this.continueDownload = true,
  });

  final String? defaultDir;
  final int split;
  final int maxConnectionPerServer;
  final String? userAgent;
  final bool continueDownload;

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
