import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/locale_controller.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif_core/arif_core.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.localeController,
    required this.session,
  });

  final LocaleController localeController;
  final SessionController session;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _dir;
  late final TextEditingController _split;
  late final TextEditingController _ua;

  @override
  void initState() {
    super.initState();
    final s = widget.session.downloadSettings;
    _dir = TextEditingController(text: s.defaultDir ?? '');
    _split = TextEditingController(text: '${s.split}');
    _ua = TextEditingController(text: s.userAgent ?? '');
  }

  @override
  void dispose() {
    _dir.dispose();
    _split.dispose();
    _ua.dispose();
    super.dispose();
  }

  void _saveDefaults() {
    final split = int.tryParse(_split.text.trim()) ?? 16;
    widget.session.updateDownloadSettings(
      AppDownloadSettings(
        defaultDir: _dir.text.trim().isEmpty ? null : _dir.text.trim(),
        split: split.clamp(1, 64),
        maxConnectionPerServer: split.clamp(1, 16),
        userAgent: _ua.text.trim().isEmpty ? null : _ua.text.trim(),
      ),
    );
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.save)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = widget.localeController.locale;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(_languageLabel(l10n, current)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
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
                    widget.localeController.useEnglish();
                  case 'zh':
                    widget.localeController.useChinese();
                  default:
                    widget.localeController.useSystem();
                }
              },
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.downloadDefaults,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _dir,
              decoration: InputDecoration(
                labelText: l10n.defaultDownloadDir,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _split,
              decoration: InputDecoration(
                labelText: l10n.connectionsSplit,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _ua,
              decoration: InputDecoration(
                labelText: l10n.userAgent,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton(
              onPressed: _saveDefaults,
              child: Text(l10n.save),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(l10n.connections),
            subtitle: Text(l10n.remoteRpcHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/connections'),
          ),
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
