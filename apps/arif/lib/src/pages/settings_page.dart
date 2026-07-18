import 'package:flutter/material.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/locale_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = localeController.locale;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(_languageLabel(l10n, current)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'system', label: Text(l10n.systemDefault)),
                ButtonSegment(value: 'en', label: Text(l10n.english)),
                ButtonSegment(value: 'zh', label: Text(l10n.chineseSimplified)),
              ],
              selected: {
                current == null
                    ? 'system'
                    : (current.languageCode == 'zh' ? 'zh' : 'en'),
              },
              onSelectionChanged: (value) {
                switch (value.first) {
                  case 'en':
                    localeController.useEnglish();
                  case 'zh':
                    localeController.useChinese();
                  default:
                    localeController.useSystem();
                }
              },
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.about),
            subtitle: Text(l10n.aboutBody),
          ),
          ListTile(
            leading: const Icon(Icons.phonelink_lock_outlined),
            title: Text(l10n.iosKeepAliveTitle),
            subtitle: Text(l10n.iosKeepAliveSummary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/ios-keep-alive'),
          ),
          ListTile(
            title: Text(l10n.versionLabel('0.1.0')),
          ),
        ],
      ),
    );
  }

  String _languageLabel(AppLocalizations l10n, Locale? locale) {
    if (locale == null) return l10n.systemDefault;
    if (locale.languageCode == 'zh') return l10n.chineseSimplified;
    return l10n.english;
  }
}
