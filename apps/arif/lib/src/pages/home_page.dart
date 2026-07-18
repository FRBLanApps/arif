import 'package:flutter/material.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/locale_controller.dart';
import 'package:arif/src/state/session_controller.dart';
import 'package:arif/src/util/format.dart';
import 'package:arif/src/widgets/task_tile.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

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

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tasks),
            actions: [
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
                onPressed: session.isConnected
                    ? () => session.refresh()
                    : () => session.connect(),
                icon: const Icon(Icons.refresh),
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
                    _StatusChip(session: session),
                    const Spacer(),
                    if (stat != null) ...[
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SegmentedButton<TaskFilter>(
                  segments: [
                    ButtonSegment(
                      value: TaskFilter.active,
                      label: Text(l10n.active),
                      icon: const Icon(Icons.play_arrow),
                    ),
                    ButtonSegment(
                      value: TaskFilter.waiting,
                      label: Text(l10n.waiting),
                      icon: const Icon(Icons.schedule),
                    ),
                    ButtonSegment(
                      value: TaskFilter.stopped,
                      label: Text(l10n.stopped),
                      icon: const Icon(Icons.stop),
                    ),
                    ButtonSegment(
                      value: TaskFilter.all,
                      label: Text(l10n.all),
                      icon: const Icon(Icons.list),
                    ),
                  ],
                  selected: {session.filter},
                  onSelectionChanged: (value) {
                    session.setFilter(value.first);
                  },
                ),
              ),
              Expanded(child: _buildBody(context, l10n, session, tasks)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addTask),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    SessionController session,
    List<DownloadTask> tasks,
  ) {
    if (!session.isConnected) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                session.phase == SessionPhase.error
                    ? l10n.connectionFailed
                    : l10n.notConnected,
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
                onPressed: () => Navigator.of(context).pushNamed('/connections'),
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
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: session.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskTile(
            task: task,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    final uri = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addTask),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.uriHint,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            keyboardType: TextInputType.url,
            minLines: 1,
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (uri == null || uri.isEmpty || !context.mounted) return;

    try {
      final gid = await widget.session.addUri(uri);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskAdded(gid))),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e is Aria2Exception ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      SessionPhase.error => (l10n.connectionFailed, Theme.of(context).colorScheme.error),
      SessionPhase.disconnected => (l10n.notConnected, Theme.of(context).colorScheme.outline),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
