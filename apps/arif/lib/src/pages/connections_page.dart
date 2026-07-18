import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

/// 连接配置页：本地引擎 / 远程 RPC、host/port/secret。
///
/// 「连接」按钮 → [SessionController.updateProfile] → connect。
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
  late EngineMode _mode;
  bool _busy = false;
  String? _binaryPath;

  @override
  void initState() {
    super.initState();
    final profile = widget.session.profile;
    final rpc = profile.rpc;
    _host = TextEditingController(text: rpc.host);
    _port = TextEditingController(text: '${rpc.port}');
    _secret = TextEditingController(text: rpc.secret ?? '');
    _useTls = rpc.useTls;
    _mode = profile.mode;
    _refreshBinary();
  }

  Future<void> _refreshBinary() async {
    final path = await widget.session.engine.locateBinary();
    if (mounted) setState(() => _binaryPath = path);
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _secret.dispose();
    super.dispose();
  }

  void _onModeChanged(EngineMode mode) {
    setState(() {
      _mode = mode;
      if (mode == EngineMode.local) {
        _host.text = '127.0.0.1';
        _useTls = false;
      }
    });
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
    final host = _mode == EngineMode.local
        ? '127.0.0.1'
        : (_host.text.trim().isEmpty ? '127.0.0.1' : _host.text.trim());

    final profile = ConnectionProfile(
      id: widget.session.profile.id,
      name: _mode == EngineMode.local ? 'Local' : 'Remote',
      mode: _mode,
      rpc: RpcConnectionConfig(
        host: host,
        port: port,
        secret: secret.isEmpty ? null : secret,
        useTls: _mode == EngineMode.local ? false : _useTls,
      ),
    );

    try {
      await widget.session.updateProfile(profile);
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    await _refreshBinary();
    if (!mounted) return;

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
    final sessionBusy = widget.session.isConnecting || _busy;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.connections)),
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.connectionMode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<EngineMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: EngineMode.local,
                    label: Text(l10n.modeLocal),
                    icon: const Icon(Icons.memory),
                  ),
                  ButtonSegment(
                    value: EngineMode.remote,
                    label: Text(l10n.modeRemote),
                    icon: const Icon(Icons.cloud_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: sessionBusy
                    ? null
                    : (value) => _onModeChanged(value.first),
              ),
              const SizedBox(height: 8),
              Text(
                _mode == EngineMode.local
                    ? l10n.localEngineHint
                    : l10n.remoteRpcHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_mode == EngineMode.local) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.terminal),
                  title: Text(l10n.engineBinary),
                  subtitle: Text(
                    _binaryPath ?? l10n.engineBinaryMissing,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _host,
                decoration: InputDecoration(
                  labelText: l10n.host,
                  border: const OutlineInputBorder(),
                  hintText: '127.0.0.1',
                  helperText: _mode == EngineMode.local
                      ? '127.0.0.1'
                      : null,
                ),
                enabled: !sessionBusy && _mode == EngineMode.remote,
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
                enabled: !sessionBusy,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _secret,
                decoration: InputDecoration(
                  labelText: l10n.rpcSecret,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !sessionBusy,
              ),
              if (_mode == EngineMode.remote)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.useTls),
                  value: _useTls,
                  onChanged:
                      sessionBusy ? null : (v) => setState(() => _useTls = v),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: sessionBusy ? null : _connect,
                icon: sessionBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(
                  sessionBusy || widget.session.isConnecting
                      ? l10n.connecting
                      : l10n.connect,
                ),
              ),
              const SizedBox(height: 24),
              _statusCard(context, l10n),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: sessionBusy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await widget.session.disconnect();
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
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

    final lines = <String>[
      '${session.profile.mode.name} · ${session.profile.rpc.host}:${session.profile.rpc.port}',
      if (session.engineVersion != null)
        l10n.engineVersion(session.engineVersion!),
      if (session.localEngineRunning) l10n.engineRunning,
      if (session.errorMessage != null) session.errorMessage!,
    ];

    return Card(
      child: ListTile(
        leading: Icon(Icons.cloud_outlined, color: color),
        title: Text(label),
        subtitle: Text(lines.join('\n')),
        isThreeLine: lines.length > 2,
      ),
    );
  }
}
