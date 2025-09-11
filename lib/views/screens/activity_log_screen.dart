import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../viewmodels/activity_log_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ActivityLogState state = ref.watch(activityLogProvider);
    final ActivityLogViewModel controller =
        ref.read(activityLogProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.constrainedWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _FiltersBar(
                  onAdd: () {
                    controller.addEntry(ActivityEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      timestamp: DateTime.now(),
                      climbType: ClimbType.bouldering,
                      grade: const Grade(
                        system: GradeSystem.vScale,
                        value: 'V3',
                      ),
                      attempts: 1,
                      completed: true,
                    ));
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _EntriesList(
                    entries: state.entries,
                    onRemove: controller.removeEntry,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: const Text('Filters (wireframe)'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList({
    required this.entries,
    required this.onRemove,
  });

  final List<ActivityEntry> entries;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState();
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final ActivityEntry e = entries[index];
        return _EntryTile(entry: e, onRemove: onRemove);
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onRemove});

  final ActivityEntry entry;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            entry.climbType == ClimbType.bouldering
                ? Icons.terrain
                : entry.climbType == ClimbType.topRope
                    ? Icons.safety_check
                    : Icons.route,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${entry.grade.value} • ${entry.climbType.name}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.attempts} attempts • '
                  '${entry.completed ? 'Sent' : 'Project'}',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => onRemove(entry.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.directions_walk, size: 48),
          SizedBox(height: AppSpacing.sm),
          Text('No activities yet. Add your first climb.'),
        ],
      ),
    );
  }
}


