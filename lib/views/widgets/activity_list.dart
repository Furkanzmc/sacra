import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../models/activity.dart';
import '../widgets/adaptive.dart';
import '../theme/app_theme.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../../viewmodels/profile_view_model.dart';

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
        final SessionLogState social = ref.watch(sessionLogProvider);
        final SessionLogViewModel socialVm = ref.read(sessionLogProvider.notifier);
        final String currentUser = ref.watch(profileProvider).displayName;
        final int likeCount = social.likesBySession[s.id]?.length ?? 0;
        final int commentCount = social.commentsBySession[s.id]?.length ?? 0;
        final bool iLiked = (social.likesBySession[s.id] ?? <String>{}).contains(currentUser);
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
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: scheme.outlineVariant, width: 1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                GestureDetector(
                                  onTap: () => socialVm.toggleLike(s.id, user: currentUser),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(iLiked ? Icons.favorite : Icons.favorite_border,
                                          size: 18, color: iLiked ? scheme.primary : tc.onContainer),
                                      const SizedBox(width: 6),
                                      Text('$likeCount',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: tc.onContainer)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _showLikesSheet(context, ref, s.id),
                                  child: _likedAvatars(
                                      context, (social.likesBySession[s.id] ?? <String>{}).toList(), tc),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => _showCommentsSheet(context, ref, s.id, currentUser),
                            icon: Icon(Icons.chat_bubble_outline, size: 18, color: tc.onContainer),
                            label: Text('$commentCount', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tc.onContainer)),
                          ),
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
  const WeeklySummaryCard({
    super.key,
    required this.sessions,
    required this.weekStart,
    this.selectedType,
    this.onTypeSelected,
  });
  final List<Session> sessions;
  final DateTime weekStart;
  final ClimbType? selectedType;
  final ValueChanged<ClimbType?>? onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final DateTime weekEnd = _endOfWeek(weekStart);
    int total = 0;
    int boulder = 0, ropeTop = 0, ropeLead = 0;
    String? maxV;
    String? maxYds;
    for (final Session s in sessions) {
      final DateTime dt = s.endTime ?? s.startTime;
      final DateTime d = DateTime(dt.year, dt.month, dt.day);
      if (!d.isBefore(weekStart) && !d.isAfter(weekEnd)) {
        total += 1;
        // Compute counts
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
        // Compute max grades
        for (final ClimbAttempt a in s.attempts) {
          if (a is BoulderingAttempt) {
            final String g = a.grade.value;
            if (maxV == null || _vIndex(g) > _vIndex(maxV)) maxV = g;
          } else if (a is TopRopeAttempt) {
            final String g = a.grade.value;
            if (maxYds == null || _ydsIndex(g) > _ydsIndex(maxYds)) maxYds = g;
          } else if (a is LeadAttempt) {
            final String g = a.grade.value;
            if (maxYds == null || _ydsIndex(g) > _ydsIndex(maxYds)) maxYds = g;
          }
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
                      GestureDetector(
                        onTap: onTypeSelected == null ? null : () => onTypeSelected!(selectedType == ClimbType.bouldering ? null : ClimbType.bouldering),
                        child: _pill(context, 'Bouldering $boulder', ClimbType.bouldering, selected: selectedType == ClimbType.bouldering),
                      ),
                      GestureDetector(
                        onTap: onTypeSelected == null ? null : () => onTypeSelected!(selectedType == ClimbType.topRope ? null : ClimbType.topRope),
                        child: _pill(context, 'Top Rope $ropeTop', ClimbType.topRope, selected: selectedType == ClimbType.topRope),
                      ),
                      GestureDetector(
                        onTap: onTypeSelected == null ? null : () => onTypeSelected!(selectedType == ClimbType.lead ? null : ClimbType.lead),
                        child: _pill(context, 'Lead $ropeLead', ClimbType.lead, selected: selectedType == ClimbType.lead),
                      ),
                      _pill(context, 'Goal $total / $weeklyGoal', null, icon: Icons.flag),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (maxV != null || maxYds != null)
                    Text(
                      'Max this week: ${maxV ?? '-'}${(maxV != null && maxYds != null) ? ' • ' : ''}${maxYds ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall,
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

Widget _pill(BuildContext context, String text, ClimbType? type, {IconData? icon, bool selected = false}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  _TypeColors tc;
  if (type != null) {
    tc = _colorsForType(type, scheme);
  } else {
    tc = _TypeColors(scheme.tertiaryContainer, scheme.onTertiaryContainer, Icons.flag);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: tc.container,
      borderRadius: BorderRadius.circular(999),
      // Always reserve space for the outline so layout doesn't shift when toggling
      border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 2),
    ),
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

int _vIndex(String v) {
  const List<String> order = <String>[
    'V0','V1','V2','V3','V4','V5','V6','V7','V8','V9','V10','V11','V12','V13','V14','V15','V16'
  ];
  final int i = order.indexOf(v);
  return i < 0 ? -1 : i;
}

int _ydsIndex(String y) {
  const List<String> order = <String>[
    '5.4','5.5','5.6','5.7','5.8','5.9',
    '5.10a','5.10b','5.10c','5.10d',
    '5.11a','5.11b','5.11c','5.11d',
    '5.12a','5.12b','5.12c','5.12d',
    '5.13a','5.13b','5.13c','5.13d',
    '5.14a','5.14b','5.14c','5.14d',
    '5.15a','5.15b','5.15c','5.15d',
  ];
  final int i = order.indexOf(y);
  return i < 0 ? -1 : i;
}

Widget _likedAvatars(BuildContext context, List<String> users, _TypeColors tc) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final List<String> show = users.length > 3 ? users.sublist(0, 3) : users;
  final double width = show.isEmpty ? 0 : (14.0 * (show.length - 1) + 16.0);
  return SizedBox(
    width: width,
    height: 16,
    child: Stack(
      clipBehavior: Clip.none,
      children: List<Widget>.generate(show.length, (int i) {
        final String name = show[i];
        final String init = _initials(name);
        return Positioned(
          left: i * 14.0,
          child: CircleAvatar(
            radius: 8,
            backgroundColor: scheme.surface,
            child: Text(init, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9, color: tc.onContainer)),
          ),
        );
      }),
    ),
  );
}

String _initials(String name) {
  final List<String> parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.isEmpty ? '?' : parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
}

Future<void> _showLikesSheet(BuildContext context, WidgetRef ref, String sessionId) async {
  final List<String> users =
      <String>[...((ref.read(sessionLogProvider).likesBySession[sessionId] ?? <String>{}))];
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Likes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Text('No likes yet'),
              )
            else
              ...users.map((String u) => ListTile(leading: const Icon(Icons.person), title: Text(u))),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      );
    },
  );
}

Future<void> _showCommentsSheet(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
  String currentUser,
) async {
  final TextEditingController ctrl = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      final List<ActivityComment> comments =
          ref.watch(sessionLogProvider).commentsBySession[sessionId] ?? <ActivityComment>[];
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Comments', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.md),
            if (comments.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Text('No comments yet'),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final ActivityComment c = comments[i];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(c.user),
                      subtitle: Text(c.text),
                      trailing: Text(adaptiveFormatTime(context, c.timestamp)),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(hintText: 'Add a comment'),
                    onSubmitted: (String v) {
                      if (v.trim().isEmpty) return;
                      ref.read(sessionLogProvider.notifier).addComment(
                            sessionId,
                            ActivityComment(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              user: currentUser,
                              text: v.trim(),
                              timestamp: DateTime.now(),
                            ),
                          );
                      ctrl.clear();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final String v = ctrl.text.trim();
                    if (v.isEmpty) return;
                    ref.read(sessionLogProvider.notifier).addComment(
                          sessionId,
                          ActivityComment(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            user: currentUser,
                            text: v,
                            timestamp: DateTime.now(),
                          ),
                        );
                    ctrl.clear();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

