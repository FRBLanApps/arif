import 'package:flutter/material.dart';
import 'package:arif/l10n/app_localizations.dart';
import 'package:arif/src/state/locale_controller.dart';
import 'package:arif_core/arif_core.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TaskFilter _filter = TaskFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tasks),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () {},
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
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
              selected: {_filter},
              onSelectionChanged: (value) {
                setState(() => _filter = value.first);
              },
            ),
          ),
          Expanded(
            child: Center(
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTask),
      ),
    );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uri)),
    );
  }
}
