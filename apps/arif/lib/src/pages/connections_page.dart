import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _secret;
  late bool _useTls;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final rpc = widget.session.profile.rpc;
    _host = TextEditingController(text: rpc.host);
    _port = TextEditingController(text: '${rpc.port}');
    _secret = TextEditingController(text: rpc.secret ?? '');
    _useTls = rpc.useTls;
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context);
    final port = int.tryParse(_port.text.trim());
    if (port == null || port <= 0 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidPort)),
      );
      return;
    }

    setState(() => _busy = true);
    final secret = _secret.text.trim();
    final profile = ConnectionProfile(
      id: widget.session.profile.id,
      name: widget.session.profile.name,
      mode: EngineMode.remote,
      rpc: RpcConnectionConfig(
        host: _host.text.trim().isEmpty ? '127.0.0.1' : _host.text.trim(),
        port: port,
        secret: secret.isEmpty ? null : secret,
        useTls: _useTls,
      ),
    );

    await widget.session.updateProfile(profile);
    if (!mounted) return;
    setState(() => _busy = false);

    final messenger = ScaffoldMessenger.of(context);
    if (widget.session.isConnected) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.connected)));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.session.errorMessage ?? l10n.connectionFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.connections)),
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.remoteRpc,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.remoteRpcHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _host,
                decoration: InputDecoration(
                  labelText: l10n.host,
                  border: const OutlineInputBorder(),
                  hintText: '127.0.0.1',
                ),
                enabled: !_busy,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _port,
                decoration: InputDecoration(
                  labelText: l10n.port,
                  border: const OutlineInputBorder(),
                  hintText: '6800',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_busy,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _secret,
                decoration: InputDecoration(
                  labelText: l10n.rpcSecret,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_busy,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.useTls),
                value: _useTls,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _useTls = v),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(
                  _busy ? l10n.connecting : l10n.connect,
                ),
              ),
              const SizedBox(height: 24),
              _statusCard(context, l10n),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await widget.session.disconnect();
                        if (mounted) setState(() => _busy = false);
                      },
                icon: const Icon(Icons.link_off),
                label: Text(l10n.disconnect),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(BuildContext context, AppLocalizations l10n) {
    final session = widget.session;
    final theme = Theme.of(context);
    final color = switch (session.phase) {
      SessionPhase.connected => theme.colorScheme.primary,
      SessionPhase.connecting => theme.colorScheme.tertiary,
      SessionPhase.error => theme.colorScheme.error,
      SessionPhase.disconnected => theme.colorScheme.outline,
    };
    final label = switch (session.phase) {
      SessionPhase.connected => l10n.connected,
      SessionPhase.connecting => l10n.connecting,
      SessionPhase.error => l10n.connectionFailed,
      SessionPhase.disconnected => l10n.notConnected,
    };

    return Card(
      child: ListTile(
        leading: Icon(Icons.cloud_outlined, color: color),
        title: Text(label),
        subtitle: Text(
          [
            '${session.profile.rpc.host}:${session.profile.rpc.port}',
            if (session.engineVersion != null)
              l10n.engineVersion(session.engineVersion!),
            if (session.errorMessage != null) session.errorMessage!,
          ].join('\n'),
        ),
        isThreeLine: session.errorMessage != null,
      ),
    );
  }
}
