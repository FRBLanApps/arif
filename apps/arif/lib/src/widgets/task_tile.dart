import 'package:flutter/material.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/util/format.dart';
import 'package:arif_core/arif_core.dart';
import 'package:arif_rpc/arif_rpc.dart';

/// 任务列表一行：名称、进度、速度、ETA、暂停/继续/删除。
///
/// [onTap] 一般进详情；按钮用 [TaskStatus.canPause] / [canResume]。
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onRemove,
    this.onTap,
  });

  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = task.progress.clamp(0.0, 1.0);
    final status = parseTaskStatus(task.status);
    final canPause = status.canPause;
    final canResume = status.canResume;
    final eta = formatEta(task.etaSeconds);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (canPause)
                    IconButton(
                      tooltip: l10n.pause,
                      onPressed: onPause,
                      icon: const Icon(Icons.pause),
                    )
                  else if (canResume)
                    IconButton(
                      tooltip: l10n.resume,
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow),
                    ),
                  IconButton(
                    tooltip: l10n.remove,
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: task.totalLength > 0 ? progress : null,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(formatProgress(progress), style: theme.textTheme.bodySmall),
                  Text(
                    '${formatBytes(task.completedLength)} / ${formatBytes(task.totalLength)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${l10n.downloadSpeed} ${formatSpeed(task.downloadSpeed)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (task.downloadSpeed > 0)
                    Text(
                      '${l10n.eta} $eta',
                      style: theme.textTheme.bodySmall,
                    ),
                  Text(
                    _statusLabel(l10n, status),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _statusColor(theme, status),
                    ),
                  ),
                ],
              ),
              if (task.errorMessage != null && task.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    task.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, TaskStatus status) {
    return switch (status) {
      TaskStatus.active => l10n.statusActive,
      TaskStatus.waiting => l10n.statusWaiting,
      TaskStatus.paused => l10n.statusPaused,
      TaskStatus.complete => l10n.statusComplete,
      TaskStatus.error => l10n.statusError,
      TaskStatus.removed => l10n.statusRemoved,
      TaskStatus.unknown => task.status,
    };
  }

  Color _statusColor(ThemeData theme, TaskStatus status) {
    return switch (status) {
      TaskStatus.active => theme.colorScheme.primary,
      TaskStatus.paused => theme.colorScheme.tertiary,
      TaskStatus.error => theme.colorScheme.error,
      TaskStatus.complete => Colors.green,
      _ => theme.colorScheme.onSurfaceVariant,
    };
  }
}
