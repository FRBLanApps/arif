import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

/// 添加 HTTP(S)/FTP 下载表单（字段对齐 Motrix AddTask 的 URI 页）。
///
/// 提交时调用 [SessionController.addHttpDownload]。
class AddHttpPage extends StatefulWidget {
  const AddHttpPage({super.key, required this.session});

  final SessionController session;

  @override
  State<AddHttpPage> createState() => _AddHttpPageState();
}

class _AddHttpPageState extends State<AddHttpPage> {
  final _uris = TextEditingController();
  final _dir = TextEditingController();
  final _out = TextEditingController();
  final _referer = TextEditingController();
  final _userAgent = TextEditingController();
  final _split = TextEditingController(text: '16');
  bool _asMirrors = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.session.downloadSettings;
    _dir.text = s.defaultDir ?? '';
    _split.text = '${s.split}';
    _userAgent.text = s.userAgent ?? '';
  }

  @override
  void dispose() {
    _uris.dispose();
    _dir.dispose();
    _out.dispose();
    _referer.dispose();
    _userAgent.dispose();
    _split.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final uris = parseUriList(_uris.text);
    if (uris.isEmpty) {
      setState(() => _error = l10n.emptyUris);
      return;
    }
    final bad = uris.where((u) => !isSupportedHttpUri(u)).toList();
    if (bad.isNotEmpty) {
      setState(() => _error = l10n.unsupportedUri(bad.first));
      return;
    }

    final split = int.tryParse(_split.text.trim()) ?? 16;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final gids = await widget.session.addHttpDownload(
        HttpDownloadRequest(
          uris: uris,
          asMirrors: _asMirrors || uris.length == 1,
          options: HttpDownloadOptions(
            dir: _dir.text.trim().isEmpty ? null : _dir.text.trim(),
            out: _out.text.trim().isEmpty ? null : _out.text.trim(),
            split: split.clamp(1, 64),
            maxConnectionPerServer: split.clamp(1, 16),
            referer:
                _referer.text.trim().isEmpty ? null : _referer.text.trim(),
            userAgent: _userAgent.text.trim().isEmpty
                ? null
                : _userAgent.text.trim(),
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tasksAdded(gids.length))),
      );
      Navigator.of(context).pop(gids);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is Aria2Exception ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addHttpTask),
        actions: [
          TextButton(
            onPressed: _busy ? null : _submit,
            child: Text(l10n.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.urisLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _uris,
            minLines: 4,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: l10n.uriHintMulti,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            enabled: !_busy,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.uriMultiHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.asMirrors),
            subtitle: Text(l10n.asMirrorsHint),
            value: _asMirrors,
            onChanged: _busy ? null : (v) => setState(() => _asMirrors = v),
          ),
          const Divider(height: 32),
          Text(
            l10n.downloadOptions,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dir,
            decoration: InputDecoration(
              labelText: l10n.downloadDir,
              border: const OutlineInputBorder(),
              hintText: l10n.downloadDirHint,
            ),
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _out,
            decoration: InputDecoration(
              labelText: l10n.fileName,
              border: const OutlineInputBorder(),
              hintText: l10n.fileNameHint,
            ),
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _split,
            decoration: InputDecoration(
              labelText: l10n.connectionsSplit,
              border: const OutlineInputBorder(),
              helperText: l10n.connectionsSplitHint,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referer,
            decoration: InputDecoration(
              labelText: l10n.referer,
              border: const OutlineInputBorder(),
            ),
            enabled: !_busy,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userAgent,
            decoration: InputDecoration(
              labelText: l10n.userAgent,
              border: const OutlineInputBorder(),
            ),
            enabled: !_busy,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_busy ? l10n.adding : l10n.startDownload),
          ),
        ],
      ),
    );
  }
}
