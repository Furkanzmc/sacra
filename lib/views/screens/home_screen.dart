import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/adaptive.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../theme/app_theme.dart';
// importing session_log_screen for consistency; replicate list inline to avoid private symbol issues
import 'active_session_screen.dart';
import '../../models/session.dart';
import '../../models/activity.dart';
import 'all_sessions_screen.dart';

String _homeClimbTypeLabel(ClimbType t) {
  switch (t) {
    case ClimbType.bouldering:
      return 'Bouldering';
    case ClimbType.topRope:
      return 'Top Rope';
    case ClimbType.lead:
      return 'Leading';
  }
}

final StateProvider<DateTime> _weekStartProvider =
    StateProvider<DateTime>((StateProviderRef<DateTime> ref) {
  return _startOfWeek(DateTime.now());
});

DateTime _startOfWeek(DateTime d) {
  final DateTime date = DateTime(d.year, d.month, d.day);
  final int weekday = date.weekday; // 1=Mon..7=Sun
  return date.subtract(Duration(days: weekday - 1));
}

DateTime _endOfWeek(DateTime start) {
  return start.add(const Duration(days: 6));
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionLogProvider); // Observe changes to refresh Home
    final DateTime weekStart = ref.watch(_weekStartProvider);
    final DateTime weekEnd = _endOfWeek(weekStart);
    return AdaptiveScaffold(
      title: const Text('Home'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _WeekHeader(weekStart: weekStart, weekEnd: weekEnd),
            const SizedBox(height: AppSpacing.sm),
            _WeeklyRingsCard(weekStart: weekStart),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _HomeSessions(weekStart: weekStart, weekEnd: weekEnd)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<Widget>(
                      builder: (_) => const AllSessionsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Show all'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSessions extends ConsumerWidget {
  const _HomeSessions({required this.weekStart, required this.weekEnd});

  final DateTime weekStart;
  final DateTime weekEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Session> all = ref.watch(sessionLogProvider).pastSessions;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Session> sessions = all
        .where((Session s) {
          final DateTime dt = s.endTime ?? s.startTime;
          final DateTime d = DateTime(dt.year, dt.month, dt.day);
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        })
        .toList()
      ..sort((Session a, Session b) =>
          (b.endTime ?? b.startTime).compareTo(a.endTime ?? a.startTime));
    if (sessions.isEmpty) {
      return const Center(child: Text('No sessions this week'));
    }
    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final Session s = sessions[index];
        final DateTime recorded = s.endTime ?? s.startTime;
        final String date = adaptiveFormatDate(context, recorded);
        final String time = adaptiveFormatTime(context, recorded);
        final int count = s.attempts.length;
        final _TypeColors tc = _colorsForType(s.climbType, scheme);
        return AdaptiveCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: tc.container,
          onTap: () {
            final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
            vm.editPastSession(s.id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (defaultTargetPlatform == TargetPlatform.iOS) {
                Navigator.of(context).push(
                  CupertinoPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                );
              }
            });
          },
          child: DefaultTextStyle.merge(
            style: TextStyle(color: tc.onContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_homeClimbTypeLabel(s.climbType),
                    style: AppTextStyles.title.copyWith(color: tc.onContainer)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Icon(tc.icon, size: 16, color: tc.onContainer),
                    const SizedBox(width: 6),
                    Text('$date • $time'),
                    const Spacer(),
                    _typeChip(context, s.climbType, tc),
                  ],
                ),
                Text('$count routes'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader({required this.weekStart, required this.weekEnd});

  final DateTime weekStart;
  final DateTime weekEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String label =
        '${adaptiveFormatDate(context, weekStart)} — ${adaptiveFormatDate(context, weekEnd)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final DateTime curr = ref.read(_weekStartProvider);
              ref.read(_weekStartProvider.notifier).state =
                  curr.subtract(const Duration(days: 7));
            },
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
            onPressed: () {
              final DateTime curr = ref.read(_weekStartProvider);
              ref.read(_weekStartProvider.notifier).state =
                  curr.add(const Duration(days: 7));
            },
          ),
        ],
      ),
    );
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

Widget _typeChip(BuildContext context, ClimbType t, _TypeColors tc) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: tc.onContainer.withOpacity(0.08),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: tc.onContainer.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(tc.icon, size: 14, color: tc.onContainer),
        const SizedBox(width: 4),
        Text(
          _homeClimbTypeLabel(t),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tc.onContainer, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
class _WeeklyRingsCard extends ConsumerWidget {
  const _WeeklyRingsCard({required this.weekStart});
  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Session> sessions = ref.watch(sessionLogProvider).pastSessions;
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
    const int weeklyGoal = 3; // placeholder goal
    final double progress =
        weeklyGoal == 0 ? 0 : (total / weeklyGoal).clamp(0.0, 1.0);
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
                      _pillForType(context, ClimbType.bouldering, 'Bouldering $boulder'),
                      _pillForType(context, ClimbType.topRope, 'Top Rope $ropeTop'),
                      _pillForType(context, ClimbType.lead, 'Lead $ropeLead'),
                      _pill(context, 'Goal $total / $weeklyGoal', icon: Icons.flag),
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

Widget _pill(BuildContext context, String text, {IconData? icon}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: icon == Icons.flag ? scheme.tertiaryContainer : scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(
            icon,
            size: 14,
            color: icon == Icons.flag ? scheme.onTertiaryContainer : scheme.onSecondaryContainer,
          ),
          const SizedBox(height: 6),
        ],
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: icon == Icons.flag ? scheme.onTertiaryContainer : scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    ),
  );
}

Widget _pillForType(BuildContext context, ClimbType type, String text) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final _TypeColors tc = _colorsForType(type, scheme);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: tc.container,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: tc.onContainer.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(tc.icon, size: 14, color: tc.onContainer),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tc.onContainer,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    ),
  );
}


