import 'package:flutter/material.dart';
import 'package:arif/l10n/app_localizations.dart';

/// In-app explanation of iOS keep-alive policy (sideload / jailbreak only).
class IosKeepAlivePage extends StatelessWidget {
  const IosKeepAlivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.iosKeepAliveTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.iosKeepAliveSummary,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _section(
            context,
            title: 'Scope',
            body:
                'iOS support in arif targets sideload and jailbreak environments only. '
                'There is no App Store distribution path for true long-running download engines.',
          ),
          _section(
            context,
            title: 'Why “abuse” keep-alive APIs',
            body:
                'iOS suspends or kills background apps aggressively. A real download engine '
                '(HTTP/BT/ED2K) needs continuous CPU and network time. Standard Background Tasks '
                'and URLSession background transfers are too limited for an aria2-class engine. '
                'arif therefore combines allowed-but-aggressive techniques (audio session tricks, '
                'voip/location-style entitlements where available, silent push, background modes, '
                'and on jailbreak: unrestricted process lifetime) to keep the engine alive.',
          ),
          _section(
            context,
            title: 'What you should expect',
            body:
                '• Battery and thermal impact will be higher than normal apps.\n'
                '• System may still kill the process under memory pressure.\n'
                '• Updates from Apple can break keep-alive techniques overnight.\n'
                '• Jailbreak builds can be more reliable than pure sideload.',
          ),
          _section(
            context,
            title: 'What we will not claim',
            body:
                'We will not market iOS arif as App Store compliant, “battery friendly”, or '
                'guaranteed 24/7. The UI and docs will keep this disclaimer visible.',
          ),
          _section(
            context,
            title: 'Engine model on iOS',
            body:
                'Unlike desktop/Android (process + JSON-RPC sidecar), iOS will host aria2-next '
                'via libaria2 + FFI inside the app process, with keep-alive layered around that '
                'process. Remote RPC to another machine remains available on all platforms.',
          ),
          const SizedBox(height: 8),
          Text(
            'Full technical notes: docs/ios-keep-alive.md',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
