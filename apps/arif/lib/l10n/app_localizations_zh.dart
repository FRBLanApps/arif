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
}
