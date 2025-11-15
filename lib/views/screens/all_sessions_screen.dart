import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../widgets/adaptive.dart';
import '../theme/app_theme.dart';
import 'active_session_screen.dart';
import '../../models/activity.dart';

class AllSessionsScreen extends ConsumerWidget {
  const AllSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Session> sessions = List<Session>.from(ref.watch(sessionLogProvider).pastSessions)
      ..sort((Session a, Session b) => (b.endTime ?? b.startTime).compareTo(a.endTime ?? a.startTime));

    final Map<String, List<Session>> byDay = <String, List<Session>>{};
    for (final Session s in sessions) {
      final DateTime d = s.endTime ?? s.startTime;
      final String key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(key, () => <Session>[]).add(s);
    }
    final List<String> keys = byDay.keys.toList()..sort((String a, String b) => b.compareTo(a));

    return AdaptiveScaffold(
      title: const Text('All Sessions'),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final String key = keys[index];
          final List<Session> daySessions = byDay[key]!;
          final parts = key.split('-');
          final DateTime d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(adaptiveFormatDate(context, d), style: AppTextStyles.title),
              const SizedBox(height: 8),
              Column(
                children: daySessions.map((Session s) {
                  final DateTime recorded = s.endTime ?? s.startTime;
                  final String time = adaptiveFormatTime(context, recorded);
                  final int count = s.attempts.length;
                  final ColorScheme scheme = Theme.of(context).colorScheme;
                  final _TypeColors tc = _colorsForType(s.climbType, scheme);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdaptiveCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: tc.container,
                      onTap: () {
                        final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                        vm.editPastSession(s.id);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).push(
                            MaterialPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                          );
                        });
                      },
                      child: DefaultTypography(
                        color: tc.onContainer,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(_homeClimbTypeLabel(s.climbType), style: AppTextStyles.title.copyWith(color: tc.onContainer)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: <void>[
                                      Icon(tc.icon, size: 14, color: tc.onContainer),
                                      const SizedBox(width: 6),
                                      Text('$time • $count routes'),
                                    ] as List<Widget>,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: tc.onContainer),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

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

class DefaultTypography extends StatelessWidget {
  const DefaultTypography({super.key, required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final TextStyle? base = Theme.of(context).textTheme.bodyMedium;
    return DefaultTextStyle.merge(
      style: (base ?? const TextStyle()).copyWith(color: color ?? base?.color),
      child: child,
    );
  }
}


