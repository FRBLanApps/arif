import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/pages/home_page.dart';
import 'package:arif/src/pages/ios_keep_alive_page.dart';
import 'package:arif/src/pages/settings_page.dart';
import 'package:arif/src/state/locale_controller.dart';

class ArifApp extends StatefulWidget {
  const ArifApp({super.key});

  @override
  State<ArifApp> createState() => _ArifAppState();
}

class _ArifAppState extends State<ArifApp> {
  final LocaleController _localeController = LocaleController();

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
            '/': (_) => HomePage(localeController: _localeController),
            '/settings': (_) => SettingsPage(localeController: _localeController),
            '/ios-keep-alive': (_) => const IosKeepAlivePage(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}
