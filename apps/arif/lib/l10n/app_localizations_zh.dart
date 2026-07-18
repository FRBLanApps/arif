// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'arif';

  @override
  String get tasks => '任务';

  @override
  String get settings => '设置';

  @override
  String get connections => '连接';

  @override
  String get addTask => '添加任务';

  @override
  String get active => '进行中';

  @override
  String get waiting => '等待中';

  @override
  String get stopped => '已停止';

  @override
  String get all => '全部';

  @override
  String get noTasks => '暂无任务';

  @override
  String get noTasksHint => '添加下载链接，或连接到远程 aria2。';

  @override
  String get downloadSpeed => '下载';

  @override
  String get uploadSpeed => '上传';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get remove => '删除';

  @override
  String get refresh => '刷新';

  @override
  String get uriHint => 'https://example.com/file.zip';

  @override
  String get add => '添加';

  @override
  String get cancel => '取消';

  @override
  String get localEngine => '本地引擎';

  @override
  String get remoteRpc => '远程 RPC';

  @override
  String get host => '主机';

  @override
  String get port => '端口';

  @override
  String get rpcSecret => 'RPC 密钥';

  @override
  String get notConnected => '未连接';

  @override
  String get connected => '已连接';

  @override
  String get connecting => '连接中…';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get engineStopped => '引擎已停止';

  @override
  String get engineRunning => '引擎运行中';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get english => 'English';

  @override
  String get chineseSimplified => '简体中文';

  @override
  String get about => '关于';

  @override
  String get aboutBody => 'arif 是面向 aria2-next 的原生管理壳（AriaNg 风格）。';

  @override
  String get iosKeepAliveTitle => 'iOS 后台保活';

  @override
  String get iosKeepAliveSummary =>
      'iOS 版本仅面向侧载 / 越狱。保活会滥用系统 API，无法上架 App Store。';

  @override
  String get iosKeepAliveLearnMore => '了解更多';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开';

  @override
  String get reconnect => '重新连接';

  @override
  String get connectHint => '连接到本机或远程 aria2 JSON-RPC（默认 127.0.0.1:6800）。';

  @override
  String get remoteRpcHint =>
      '连接已在运行的 aria2 / aria2-next。请先用 --enable-rpc 开启 RPC。';

  @override
  String get useTls => '使用 TLS';

  @override
  String get invalidPort => '请输入有效端口（1–65535）。';

  @override
  String engineVersion(String version) {
    return 'aria2 $version';
  }

  @override
  String taskAdded(String gid) {
    return '已添加任务 $gid';
  }

  @override
  String get connectionMode => '模式';

  @override
  String get modeLocal => '本地引擎';

  @override
  String get modeRemote => '仅远程 RPC';

  @override
  String get localEngineHint =>
      '若本机该端口已有 aria2 则复用；否则启动托管的 aria2-next/aria2c 进程。';

  @override
  String get engineBinary => '引擎二进制';

  @override
  String get engineBinaryMissing => '未找到（请安装 aria2 或设置 ARIF_ENGINE_PATH）';

  @override
  String get addHttpTask => '添加 HTTP 下载';

  @override
  String get urisLabel => '链接';

  @override
  String get uriHintMulti =>
      'https://example.com/a.zip\nhttps://example.com/b.zip';

  @override
  String get uriMultiHint => '每行一个链接。多行默认各自建任务；开启「镜像」则合并为同一任务。';

  @override
  String get asMirrors => '作为镜像源';

  @override
  String get asMirrorsHint => '所有链接下载同一文件（单个任务）。';

  @override
  String get downloadOptions => '下载选项';

  @override
  String get downloadDir => '下载目录';

  @override
  String get downloadDirHint => '留空则使用引擎默认目录';

  @override
  String get fileName => '文件名';

  @override
  String get fileNameHint => '可选输出文件名（out）';

  @override
  String get connectionsSplit => '连接数 (split)';

  @override
  String get connectionsSplitHint =>
      '对应 aria2 的 split / max-connection-per-server';

  @override
  String get referer => 'Referer';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get startDownload => '开始下载';

  @override
  String get adding => '添加中…';

  @override
  String get emptyUris => '请至少输入一个链接。';

  @override
  String unsupportedUri(String uri) {
    return '不支持的链接：$uri';
  }

  @override
  String tasksAdded(int count) {
    return '已添加 $count 个任务';
  }

  @override
  String get taskDetail => '任务详情';

  @override
  String get taskNotFound => '找不到任务';

  @override
  String get status => '状态';

  @override
  String get gid => 'GID';

  @override
  String get eta => '剩余时间';

  @override
  String get uri => '链接';

  @override
  String get error => '错误';

  @override
  String get files => '文件';

  @override
  String get copied => '已复制';

  @override
  String get pauseAll => '全部暂停';

  @override
  String get resumeAll => '全部继续';

  @override
  String get statusActive => '下载中';

  @override
  String get statusWaiting => '等待中';

  @override
  String get statusPaused => '已暂停';

  @override
  String get statusComplete => '已完成';

  @override
  String get statusError => '错误';

  @override
  String get statusRemoved => '已移除';

  @override
  String get defaultDownloadDir => '默认下载目录';

  @override
  String get downloadDefaults => '下载默认值';

  @override
  String get save => '保存';
}
