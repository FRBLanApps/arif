import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'arif'**
  String get appTitle;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasks;

  /// No description provided for @noTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Add a URL or connect to a remote aria2 instance.'**
  String get noTasksHint;

  /// No description provided for @downloadSpeed.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get downloadSpeed;

  /// No description provided for @uploadSpeed.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get uploadSpeed;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @uriHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/file.zip'**
  String get uriHint;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @localEngine.
  ///
  /// In en, this message translates to:
  /// **'Local engine'**
  String get localEngine;

  /// No description provided for @remoteRpc.
  ///
  /// In en, this message translates to:
  /// **'Remote RPC'**
  String get remoteRpc;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @rpcSecret.
  ///
  /// In en, this message translates to:
  /// **'RPC secret'**
  String get rpcSecret;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @engineStopped.
  ///
  /// In en, this message translates to:
  /// **'Engine stopped'**
  String get engineStopped;

  /// No description provided for @engineRunning.
  ///
  /// In en, this message translates to:
  /// **'Engine running'**
  String get engineRunning;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chineseSimplified.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get chineseSimplified;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'arif is a native shell for aria2-next (AriaNg-style manager).'**
  String get aboutBody;

  /// No description provided for @iosKeepAliveTitle.
  ///
  /// In en, this message translates to:
  /// **'iOS background keep-alive'**
  String get iosKeepAliveTitle;

  /// No description provided for @iosKeepAliveSummary.
  ///
  /// In en, this message translates to:
  /// **'iOS builds are for sideload / jailbreak only. Keep-alive uses aggressive system APIs and is not App Store safe.'**
  String get iosKeepAliveSummary;

  /// No description provided for @iosKeepAliveLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get iosKeepAliveLearnMore;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @connectHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to a local or remote aria2 JSON-RPC endpoint (default 127.0.0.1:6800).'**
  String get connectHint;

  /// No description provided for @remoteRpcHint.
  ///
  /// In en, this message translates to:
  /// **'Talk to an already-running aria2 / aria2-next instance. Enable RPC with --enable-rpc.'**
  String get remoteRpcHint;

  /// No description provided for @useTls.
  ///
  /// In en, this message translates to:
  /// **'Use TLS'**
  String get useTls;

  /// No description provided for @invalidPort.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid port (1–65535).'**
  String get invalidPort;

  /// No description provided for @engineVersion.
  ///
  /// In en, this message translates to:
  /// **'aria2 {version}'**
  String engineVersion(String version);

  /// No description provided for @taskAdded.
  ///
  /// In en, this message translates to:
  /// **'Added task {gid}'**
  String taskAdded(String gid);

  /// No description provided for @connectionMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get connectionMode;

  /// No description provided for @modeLocal.
  ///
  /// In en, this message translates to:
  /// **'Local engine'**
  String get modeLocal;

  /// No description provided for @modeRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote RPC only'**
  String get modeRemote;

  /// No description provided for @localEngineHint.
  ///
  /// In en, this message translates to:
  /// **'Reuse RPC on this port if aria2 is already running; otherwise start a managed aria2-next/aria2c process.'**
  String get localEngineHint;

  /// No description provided for @engineBinary.
  ///
  /// In en, this message translates to:
  /// **'Engine binary'**
  String get engineBinary;

  /// No description provided for @engineBinaryMissing.
  ///
  /// In en, this message translates to:
  /// **'Not found (install aria2 or set ARIF_ENGINE_PATH)'**
  String get engineBinaryMissing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
