import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../models/activity.dart';
import '../widgets/adaptive.dart';
import '../theme/app_theme.dart';

class ActivityListItem {
  ActivityListItem({required this.session, this.owner});
  final Session session;
  final String? owner; // e.g., "You", "Ava"
}

class ActivityList extends ConsumerWidget {
  const ActivityList({super.key, required this.items, this.onTap});
  final List<ActivityListItem> items;
  final void Function(Session session)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('No sessions'));
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final ActivityListItem item = items[index];
        final Session s = item.session;
        final DateTime recorded = s.endTime ?? s.startTime;
        final String date = adaptiveFormatDate(context, recorded);
        final String time = adaptiveFormatTime(context, recorded);
        final int count = s.attempts.length;
        final _TypeColors tc = _colorsForType(s.climbType, scheme);
        return AdaptiveCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: tc.container,
          onTap: onTap == null ? null : () => onTap!(s),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: tc.onContainer),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          if (item.owner != null) ...<Widget>[
                            Text(item.owner!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tc.onContainer)),
                            const SizedBox(width: 8),
                            const Text('•'),
                            const SizedBox(width: 8),
                          ],
                          Text(_activityTypeLabel(s.climbType), style: AppTextStyles.title.copyWith(color: tc.onContainer)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(tc.icon, size: 14, color: tc.onContainer),
                          const SizedBox(width: 6),
                          Text('$date • $time'),
                          const SizedBox(width: 8),
                          Text('• $count routes'),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: tc.onContainer),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WeekHeader extends ConsumerWidget {
  const WeekHeader({super.key, required this.weekStart, required this.onChange});
  final DateTime weekStart;
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime weekEnd = _endOfWeek(weekStart);
    final String label = '${adaptiveFormatDate(context, weekStart)} — ${adaptiveFormatDate(context, weekEnd)}';
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChange(weekStart.subtract(const Duration(days: 7))),
        ),
        Expanded(
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChange(weekStart.add(const Duration(days: 7))),
        ),
      ],
    );
  }
}

class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key, required this.sessions, required this.weekStart});
  final List<Session> sessions;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final DateTime weekEnd = _endOfWeek(weekStart);
    int total = 0;
    int boulder = 0, ropeTop = 0, ropeLead = 0;
    for (final Session s in sessions) {
      final DateTime dt = s.endTime ?? s.startTime;
      final DateTime d = DateTime(dt.year, dt.month, dt.day);
      if (!d.isBefore(weekStart) && !d.isAfter(weekEnd)) {
        total += 1;
        switch (s.climbType) {
          case ClimbType.bouldering:
            boulder++;
            break;
          case ClimbType.topRope:
            ropeTop++;
            break;
          case ClimbType.lead:
            ropeLead++;
            break;
        }
      }
    }
    const int weeklyGoal = 3;
    final double progress = weeklyGoal == 0 ? 0 : (total / weeklyGoal).clamp(0.0, 1.0);
    return AdaptiveCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 140,
        child: Row(
          children: <Widget>[
            _SummaryRing(value: progress, label: '$total'),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('This week', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _pill(context, 'Bouldering $boulder', ClimbType.bouldering),
                      _pill(context, 'Top Rope $ropeTop', ClimbType.topRope),
                      _pill(context, 'Lead $ropeLead', ClimbType.lead),
                      _pill(context, 'Goal $total / $weeklyGoal', null, icon: Icons.flag),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRing extends StatelessWidget {
  const _SummaryRing({required this.value, required this.label});
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('Sessions', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

Widget _pill(BuildContext context, String text, ClimbType? type, {IconData? icon}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  _TypeColors tc;
  if (type != null) {
    tc = _colorsForType(type, scheme);
  } else {
    tc = _TypeColors(scheme.tertiaryContainer, scheme.onTertiaryContainer, Icons.flag);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: tc.container, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 14, color: tc.onContainer),
          const SizedBox(width: 6),
        ],
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tc.onContainer, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

String _activityTypeLabel(ClimbType t) {
  switch (t) {
    case ClimbType.bouldering:
      return 'Bouldering';
    case ClimbType.topRope:
      return 'Top Rope';
    case ClimbType.lead:
      return 'Leading';
  }
}

class _TypeColors {
  const _TypeColors(this.container, this.onContainer, this.icon);
  final Color container;
  final Color onContainer;
  final IconData icon;
}

_TypeColors _colorsForType(ClimbType t, ColorScheme scheme) {
  switch (t) {
    case ClimbType.bouldering:
      return _TypeColors(scheme.secondaryContainer, scheme.onSecondaryContainer, Icons.terrain);
    case ClimbType.topRope:
      return _TypeColors(scheme.tertiaryContainer, scheme.onTertiaryContainer, Icons.safety_check);
    case ClimbType.lead:
      return _TypeColors(scheme.primaryContainer, scheme.onPrimaryContainer, Icons.route);
  }
}

DateTime _endOfWeek(DateTime start) => start.add(const Duration(days: 6));

