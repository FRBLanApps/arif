import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/pages/connections_page.dart';
import 'package:arif/src/pages/home_page.dart';
import 'package:arif/src/pages/ios_keep_alive_page.dart';
import 'package:arif/src/pages/settings_page.dart';
import 'package:arif/src/state/locale_controller.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif_core/arif_core.dart';

class ArifApp extends StatefulWidget {
  const ArifApp({
    super.key,
    this.session,
    this.autoConnect = true,
  });

  /// Optional injected session (tests).
  final SessionController? session;
  final bool autoConnect;

  @override
  State<ArifApp> createState() => _ArifAppState();
}

class _ArifAppState extends State<ArifApp> {
  final LocaleController _localeController = LocaleController();
  late final SessionController _session;
  late final bool _ownsSession;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    _session = widget.session ??
        SessionController(
          profile: ConnectionProfile.localDefault(),
        );
    if (widget.autoConnect) {
      // Connect to existing local aria2 (127.0.0.1:6800) by default.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _session.connect();
      });
    }
  }

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
    }
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _localeController,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: _localeController.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF90CAF9),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          routes: {
            '/': (_) => HomePage(
                  localeController: _localeController,
                  session: _session,
                ),
            '/settings': (_) =>
                SettingsPage(localeController: _localeController),
            '/connections': (_) => ConnectionsPage(session: _session),
            '/ios-keep-alive': (_) => const IosKeepAlivePage(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}
