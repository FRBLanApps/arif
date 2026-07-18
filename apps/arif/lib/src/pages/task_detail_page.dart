import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif/src/util/format.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

/// 单个任务详情：进度 / 速度 / ETA / 文件列表 / 暂停删除。
///
/// 进入时 [fetchTask] 拉一次全量；之后监听 [SessionController] 列表刷新。
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.session,
    required this.gid,
  });

  final SessionController session;

  /// aria2 任务 GID。
  final String gid;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  DownloadTask? _task;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _task = widget.session.findTask(widget.gid);
    _load();
    widget.session.addListener(_onSession);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    final t = widget.session.findTask(widget.gid);
    if (t != null && mounted) {
      setState(() => _task = t);
    }
  }

  Future<void> _load() async {
    try {
      final t = await widget.session.fetchTask(widget.gid);
      if (mounted) {
        setState(() {
          _task = t;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is Aria2Exception ? e.message : e.toString();
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e is Aria2Exception ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final task = _task;
    final status = parseTaskStatus(task?.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskDetail),
        actions: [
          if (task != null && status.canPause)
            IconButton(
              tooltip: l10n.pause,
              onPressed: () => _run(() => widget.session.pause(task.gid)),
              icon: const Icon(Icons.pause),
            ),
          if (task != null && status.canResume)
            IconButton(
              tooltip: l10n.resume,
              onPressed: () => _run(() => widget.session.unpause(task.gid)),
              icon: const Icon(Icons.play_arrow),
            ),
          if (task != null)
            IconButton(
              tooltip: l10n.remove,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.remove),
                    content: Text(task.displayName),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.remove),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await _run(() => widget.session.remove(task.gid));
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading && task == null
          ? const Center(child: CircularProgressIndicator())
          : task == null
              ? Center(child: Text(_error ?? l10n.taskNotFound))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        task.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: task.totalLength > 0
                            ? task.progress.clamp(0.0, 1.0)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatProgress(task.progress)} · '
                        '${formatBytes(task.completedLength)} / '
                        '${formatBytes(task.totalLength)}',
                      ),
                      const SizedBox(height: 16),
                      _row(l10n.status, task.status),
                      _row(l10n.gid, task.gid, copyable: true),
                      _row(
                        l10n.downloadSpeed,
                        formatSpeed(task.downloadSpeed),
                      ),
                      _row(
                        l10n.uploadSpeed,
                        formatSpeed(task.uploadSpeed),
                      ),
                      _row(l10n.connections, '${task.connections}'),
                      _row(l10n.eta, formatEta(task.etaSeconds)),
                      if (task.dir != null) _row(l10n.downloadDir, task.dir!),
                      if (task.primaryUri != null)
                        _row(l10n.uri, task.primaryUri!, copyable: true),
                      if (task.errorMessage != null &&
                          task.errorMessage!.isNotEmpty)
                        _row(
                          l10n.error,
                          task.errorMessage!,
                          error: true,
                        ),
                      if (task.files.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.files,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...task.files.map(
                          (f) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              f.path?.isNotEmpty == true
                                  ? f.path!
                                  : '#${f.index}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${formatBytes(f.completedLength)} / '
                              '${formatBytes(f.length)}',
                            ),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool copyable = false,
    bool error = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: error ? theme.colorScheme.error : null,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                final l10n = AppLocalizations.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.copied)),
                );
              },
            ),
        ],
      ),
    );
  }
}
