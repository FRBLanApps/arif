import 'package:flutter/material.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/pages/add_http_page.dart';
import 'package:arif/src/pages/task_detail_page.dart';
import 'package:arif/src/state/locale_controller.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif/src/util/format.dart';
import 'package:arif/src/widgets/task_tile.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

/// 任务壳首页：连接状态、分栏列表、添加 HTTP 下载入口。
///
/// 所有数据来自 [SessionController]；本页不直接调 RPC。
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.localeController,
    required this.session,
  });

  final LocaleController localeController;
  final SessionController session;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = widget.session;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final tasks = session.visibleTasks;
        final stat = session.globalStat;
        final canAct = session.isConnected;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tasks),
            actions: [
              if (canAct) ...[
                IconButton(
                  tooltip: l10n.pauseAll,
                  onPressed: () => _runAction(session.pauseAll),
                  icon: const Icon(Icons.pause_circle_outline),
                ),
                IconButton(
                  tooltip: l10n.resumeAll,
                  onPressed: () => _runAction(session.unpauseAll),
                  icon: const Icon(Icons.play_circle_outline),
                ),
              ],
              IconButton(
                tooltip: l10n.connections,
                onPressed: () =>
                    Navigator.of(context).pushNamed('/connections'),
                icon: Icon(
                  session.isConnected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
              ),
              IconButton(
                tooltip: l10n.refresh,
                onPressed: session.isConnecting
                    ? null
                    : () {
                        if (session.isConnected) {
                          session.refresh();
                        } else {
                          session.connect();
                        }
                      },
                icon: session.isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: l10n.settings,
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Flexible(child: _StatusChip(session: session)),
                    if (stat != null && session.isConnected) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${l10n.downloadSpeed} ${formatSpeed(stat.downloadSpeed)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${l10n.uploadSpeed} ${formatSpeed(stat.uploadSpeed)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 420;
                    return SegmentedButton<TaskFilter>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: TaskFilter.active,
                          label: Text(
                            compact
                                ? l10n.active
                                : '${l10n.active} (${session.activeTasks.length})',
                          ),
                          icon: compact ? null : const Icon(Icons.play_arrow),
                        ),
                        ButtonSegment(
                          value: TaskFilter.waiting,
                          label: Text(
                            compact
                                ? l10n.waiting
                                : '${l10n.waiting} (${session.waitingTasks.length})',
                          ),
                          icon: compact ? null : const Icon(Icons.schedule),
                        ),
                        ButtonSegment(
                          value: TaskFilter.stopped,
                          label: Text(
                            compact
                                ? l10n.stopped
                                : '${l10n.stopped} (${session.stoppedTasks.length})',
                          ),
                          icon: compact ? null : const Icon(Icons.stop),
                        ),
                        ButtonSegment(
                          value: TaskFilter.all,
                          label: Text(
                            compact
                                ? l10n.all
                                : '${l10n.all} (${session.allTasks.length})',
                          ),
                          icon: compact ? null : const Icon(Icons.list),
                        ),
                      ],
                      selected: {session.filter},
                      onSelectionChanged: (value) {
                        session.setFilter(value.first);
                      },
                    );
                  },
                ),
              ),
              Expanded(child: _buildBody(context, l10n, session, tasks)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: canAct
                ? () => _openAddHttp(context)
                : () => Navigator.of(context).pushNamed('/connections'),
            icon: Icon(canAct ? Icons.add : Icons.link),
            label: Text(canAct ? l10n.addTask : l10n.connections),
          ),
        );
      },
    );
  }

  Future<void> _openAddHttp(BuildContext context) async {
    await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => AddHttpPage(session: widget.session),
      ),
    );
  }

  void _openDetail(DownloadTask task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(
          session: widget.session,
          gid: task.gid,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    SessionController session,
    List<DownloadTask> tasks,
  ) {
    if (session.isConnecting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.connecting,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (!session.isConnected) {
      final isError = session.phase == SessionPhase.error;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.cloud_off_outlined,
                size: 64,
                color: isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                isError ? l10n.connectionFailed : l10n.notConnected,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                session.errorMessage ?? l10n.connectHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/connections'),
                icon: const Icon(Icons.link),
                label: Text(l10n.connections),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => session.connect(),
                child: Text(l10n.reconnect),
              ),
            ],
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noTasks,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noTasksHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openAddHttp(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.addHttpTask),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: session.refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskTile(
            task: task,
            onTap: () => _openDetail(task),
            onPause: () => _runAction(() => session.pause(task.gid)),
            onResume: () => _runAction(() => session.unpause(task.gid)),
            onRemove: () => _confirmRemove(task),
          );
        },
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final message = e is Aria2Exception ? e.message : e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmRemove(DownloadTask task) async {
    final l10n = AppLocalizations.of(context);
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
      await _runAction(() => widget.session.remove(task.gid));
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (session.phase) {
      SessionPhase.connected => (
          session.engineVersion != null
              ? l10n.engineVersion(session.engineVersion!)
              : l10n.connected,
          Colors.green,
        ),
      SessionPhase.connecting => (l10n.connecting, Colors.orange),
      SessionPhase.error => (
          l10n.connectionFailed,
          Theme.of(context).colorScheme.error
        ),
      SessionPhase.disconnected => (
          l10n.notConnected,
          Theme.of(context).colorScheme.outline
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
