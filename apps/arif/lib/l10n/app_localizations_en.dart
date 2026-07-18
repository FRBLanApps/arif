// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'arif';

  @override
  String get tasks => 'Tasks';

  @override
  String get settings => 'Settings';

  @override
  String get connections => 'Connections';

  @override
  String get addTask => 'Add task';

  @override
  String get active => 'Active';

  @override
  String get waiting => 'Waiting';

  @override
  String get stopped => 'Stopped';

  @override
  String get all => 'All';

  @override
  String get noTasks => 'No tasks yet';

  @override
  String get noTasksHint => 'Add a URL or connect to a remote aria2 instance.';

  @override
  String get downloadSpeed => 'Down';

  @override
  String get uploadSpeed => 'Up';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get remove => 'Remove';

  @override
  String get refresh => 'Refresh';

  @override
  String get uriHint => 'https://example.com/file.zip';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get localEngine => 'Local engine';

  @override
  String get remoteRpc => 'Remote RPC';

  @override
  String get host => 'Host';

  @override
  String get port => 'Port';

  @override
  String get rpcSecret => 'RPC secret';

  @override
  String get notConnected => 'Not connected';

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting…';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get engineStopped => 'Engine stopped';

  @override
  String get engineRunning => 'Engine running';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get english => 'English';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'arif is a native shell for aria2-next (AriaNg-style manager).';

  @override
  String get iosKeepAliveTitle => 'iOS background keep-alive';

  @override
  String get iosKeepAliveSummary =>
      'iOS builds are for sideload / jailbreak only. Keep-alive uses aggressive system APIs and is not App Store safe.';

  @override
  String get iosKeepAliveLearnMore => 'Learn more';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get connectHint =>
      'Connect to a local or remote aria2 JSON-RPC endpoint (default 127.0.0.1:6800).';

  @override
  String get remoteRpcHint =>
      'Talk to an already-running aria2 / aria2-next instance. Enable RPC with --enable-rpc.';

  @override
  String get useTls => 'Use TLS';

  @override
  String get invalidPort => 'Enter a valid port (1–65535).';

  @override
  String engineVersion(String version) {
    return 'aria2 $version';
  }

  @override
  String taskAdded(String gid) {
    return 'Added task $gid';
  }

  @override
  String get connectionMode => 'Mode';

  @override
  String get modeLocal => 'Local engine';

  @override
  String get modeRemote => 'Remote RPC only';

  @override
  String get localEngineHint =>
      'Reuse RPC on this port if aria2 is already running; otherwise start a managed aria2-next/aria2c process.';

  @override
  String get engineBinary => 'Engine binary';

  @override
  String get engineBinaryMissing =>
      'Not found (install aria2 or set ARIF_ENGINE_PATH)';

  @override
  String get addHttpTask => 'Add HTTP download';

  @override
  String get urisLabel => 'URLs';

  @override
  String get uriHintMulti =>
      'https://example.com/a.zip\nhttps://example.com/b.zip';

  @override
  String get uriMultiHint =>
      'One URL per line. Multiple lines create separate tasks unless “mirrors” is enabled.';

  @override
  String get asMirrors => 'Use as mirrors';

  @override
  String get asMirrorsHint => 'All URLs download the same file (single task).';

  @override
  String get downloadOptions => 'Options';

  @override
  String get downloadDir => 'Download directory';

  @override
  String get downloadDirHint => 'Leave empty to use engine default';

  @override
  String get fileName => 'File name';

  @override
  String get fileNameHint => 'Optional output name (out)';

  @override
  String get connectionsSplit => 'Connections (split)';

  @override
  String get connectionsSplitHint => 'aria2 split / max-connection-per-server';

  @override
  String get referer => 'Referer';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get startDownload => 'Start download';

  @override
  String get adding => 'Adding…';

  @override
  String get emptyUris => 'Enter at least one URL.';

  @override
  String unsupportedUri(String uri) {
    return 'Unsupported URI: $uri';
  }

  @override
  String tasksAdded(int count) {
    return 'Added $count task(s)';
  }

  @override
  String get taskDetail => 'Task detail';

  @override
  String get taskNotFound => 'Task not found';

  @override
  String get status => 'Status';

  @override
  String get gid => 'GID';

  @override
  String get eta => 'ETA';

  @override
  String get uri => 'URI';

  @override
  String get error => 'Error';

  @override
  String get files => 'Files';

  @override
  String get copied => 'Copied';

  @override
  String get pauseAll => 'Pause all';

  @override
  String get resumeAll => 'Resume all';

  @override
  String get statusActive => 'active';

  @override
  String get statusWaiting => 'waiting';

  @override
  String get statusPaused => 'paused';

  @override
  String get statusComplete => 'complete';

  @override
  String get statusError => 'error';

  @override
  String get statusRemoved => 'removed';

  @override
  String get defaultDownloadDir => 'Default download directory';

  @override
  String get downloadDefaults => 'Download defaults';

  @override
  String get save => 'Save';
}
