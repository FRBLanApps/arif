import 'package:flutter/material.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/util/format.dart';
import 'package:arif_rpc/arif_rpc.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onRemove,
  });

  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = task.progress.clamp(0.0, 1.0);
    final canPause = task.status == 'active' || task.status == 'waiting';
    final canResume = task.status == 'paused';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            LinearProgressIndicator(value: progress > 0 ? progress : null),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  formatProgress(progress),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${formatBytes(task.completedLength)} / ${formatBytes(task.totalLength)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${l10n.downloadSpeed} ${formatSpeed(task.downloadSpeed)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${l10n.uploadSpeed} ${formatSpeed(task.uploadSpeed)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  task.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (task.errorMessage != null && task.errorMessage!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
