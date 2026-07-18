/// Global transfer statistics from `aria2.getGlobalStat`.
class GlobalStat {
  const GlobalStat({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.numActive,
    required this.numWaiting,
    required this.numStopped,
    required this.numStoppedTotal,
  });

  final int downloadSpeed;
  final int uploadSpeed;
  final int numActive;
  final int numWaiting;
  final int numStopped;
  final int numStoppedTotal;

  factory GlobalStat.fromJson(Map<String, dynamic> json) {
    return GlobalStat(
      downloadSpeed: _asInt(json['downloadSpeed']),
      uploadSpeed: _asInt(json['uploadSpeed']),
      numActive: _asInt(json['numActive']),
      numWaiting: _asInt(json['numWaiting']),
      numStopped: _asInt(json['numStopped']),
      numStoppedTotal: _asInt(json['numStoppedTotal']),
    );
  }
}

/// Download task snapshot from tell* RPC methods.
class DownloadTask {
  const DownloadTask({
    required this.gid,
    required this.status,
    required this.totalLength,
    required this.completedLength,
    required this.uploadLength,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.connections,
    this.dir,
    this.errorCode,
    this.errorMessage,
    this.files = const [],
    this.bittorrent,
    this.followedBy = const [],
    this.following,
    this.belongsTo,
    this.infoHash,
  });

  final String gid;
  final String status;
  final int totalLength;
  final int completedLength;
  final int uploadLength;
  final int downloadSpeed;
  final int uploadSpeed;
  final int connections;
  final String? dir;
  final String? errorCode;
  final String? errorMessage;
  final List<DownloadFile> files;
  final Map<String, dynamic>? bittorrent;
  final List<String> followedBy;
  final String? following;
  final String? belongsTo;
  final String? infoHash;

  double get progress {
    if (totalLength <= 0) return 0;
    return completedLength / totalLength;
  }

  int get remainingLength {
    final left = totalLength - completedLength;
    return left < 0 ? 0 : left;
  }

  /// ETA in seconds when speed > 0 and total known; otherwise null.
  int? get etaSeconds {
    if (downloadSpeed <= 0 || totalLength <= 0) return null;
    final left = remainingLength;
    if (left <= 0) return 0;
    return (left / downloadSpeed).ceil();
  }

  String get displayName {
    if (files.isNotEmpty) {
      final path = files.first.path;
      if (path != null && path.isNotEmpty) {
        final parts = path.replaceAll('\\', '/').split('/');
        final name = parts.isNotEmpty ? parts.last : path;
        if (name.isNotEmpty) return name;
      }
      if (files.first.uris.isNotEmpty) {
        final uri = files.first.uris.first;
        try {
          final segments = Uri.parse(uri).pathSegments;
          if (segments.isNotEmpty && segments.last.isNotEmpty) {
            return Uri.decodeComponent(segments.last);
          }
        } catch (_) {}
      }
    }
    return gid;
  }

  String? get primaryUri {
    if (files.isEmpty) return null;
    if (files.first.uris.isEmpty) return null;
    return files.first.uris.first;
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    final followedRaw = json['followedBy'];
    return DownloadTask(
      gid: json['gid'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      totalLength: _asInt(json['totalLength']),
      completedLength: _asInt(json['completedLength']),
      uploadLength: _asInt(json['uploadLength']),
      downloadSpeed: _asInt(json['downloadSpeed']),
      uploadSpeed: _asInt(json['uploadSpeed']),
      connections: _asInt(json['connections']),
      dir: json['dir'] as String?,
      errorCode: json['errorCode']?.toString(),
      errorMessage: json['errorMessage'] as String?,
      files: filesRaw is List
          ? filesRaw
              .whereType<Map>()
              .map((e) => DownloadFile.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      bittorrent: json['bittorrent'] is Map
          ? Map<String, dynamic>.from(json['bittorrent'] as Map)
          : null,
      followedBy: followedRaw is List
          ? followedRaw.map((e) => e.toString()).toList()
          : const [],
      following: json['following'] as String?,
      belongsTo: json['belongsTo'] as String?,
      infoHash: json['infoHash'] as String?,
    );
  }
}

class DownloadFile {
  const DownloadFile({
    required this.index,
    this.path,
    required this.length,
    required this.completedLength,
    required this.selected,
    this.uris = const [],
  });

  final int index;
  final String? path;
  final int length;
  final int completedLength;
  final bool selected;
  final List<String> uris;

  factory DownloadFile.fromJson(Map<String, dynamic> json) {
    final urisRaw = json['uris'];
    return DownloadFile(
      index: _asInt(json['index']),
      path: json['path'] as String?,
      length: _asInt(json['length']),
      completedLength: _asInt(json['completedLength']),
      selected: (json['selected']?.toString() ?? 'true') == 'true',
      uris: urisRaw is List
          ? urisRaw
              .whereType<Map>()
              .map((e) => e['uri']?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

class VersionInfo {
  const VersionInfo({
    required this.version,
    required this.enabledFeatures,
  });

  final String version;
  final List<String> enabledFeatures;

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    final features = json['enabledFeatures'];
    return VersionInfo(
      version: json['version'] as String? ?? '',
      enabledFeatures: features is List
          ? features.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

int _asInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}
