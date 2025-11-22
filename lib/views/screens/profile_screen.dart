import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/profile_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/adaptive.dart';
import 'settings_screen.dart';
import '../widgets/activity_list.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../../models/session.dart';
import '../widgets/gym_picker.dart';
import '../../models/activity.dart';
import 'active_session_screen.dart';
import '../widgets/v_grade_scrubber.dart';

final StateProvider<bool> _profileEditingProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

// Persist week selection across rebuilds
final StateProvider<DateTime> _profileWeekStartProvider =
    StateProvider<DateTime>((StateProviderRef<DateTime> ref) => _startOfWeek(DateTime.now()));
final StateProvider<ClimbType?> _profileTypeFilterProvider =
    StateProvider<ClimbType?>((StateProviderRef<ClimbType?> ref) => null);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileState state = ref.watch(profileProvider);
    final bool isEditing = ref.watch(_profileEditingProvider);
    // final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime weekStart = ref.watch(_profileWeekStartProvider);
    final List<Session> all = ref.watch(sessionLogProvider).pastSessions;
    final DateTime weekEnd = _endOfWeek(weekStart);
    final ClimbType? selectedType = ref.watch(_profileTypeFilterProvider);
    final List<Session> weekSessions = all
        .where((Session s) {
          final DateTime dt = s.endTime ?? s.startTime;
          final DateTime d = DateTime(dt.year, dt.month, dt.day);
          if (d.isBefore(weekStart) || d.isAfter(weekEnd)) return false;
          if (selectedType != null && s.climbType != selectedType) return false;
          return true;
        })
        .toList()
      ..sort((Session a, Session b) => (b.endTime ?? b.startTime).compareTo(a.endTime ?? a.startTime));
    return AdaptiveScaffold(
      title: const Text('Profile'),
      actions: <Widget>[
        AdaptiveIconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<Widget>(builder: (_) => const SettingsScreen()));
          },
          tooltip: 'Settings',
          icon: Icon(defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.gear_alt : Icons.settings),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.constrainedWidth(context)),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              Row(
                children: <Widget>[
                  _ProfilePhoto(
                    photoUrl: state.photoUrl,
                    initials: _initials(state.displayName),
                    isEditing: isEditing,
                    onTap: () async {
                      if (!isEditing) {
                        ref.read(_profileEditingProvider.notifier).state = true;
                        return;
                      }
                      await _showPhotoActions(context, ref);
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _LabeledField(
                          label: 'Name',
                          child: isEditing
                              ? _InlineEditableText(
                                  value: state.displayName,
                                  onChanged: (String v) => ref.read(profileProvider.notifier).updateName(v),
                                )
                              : Text(state.displayName, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _LabeledField(
                          label: 'Location',
                          icon: Icons.location_on_outlined,
                          child: isEditing
                              ? _InlineEditableText(
                                  value: state.location ?? '',
                                  hintText: 'Add location',
                                  onChanged: (String v) => ref.read(profileProvider.notifier).updateLocation(v),
                                )
                              : Text(state.location ?? 'Not set', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _LabeledField(
                          label: 'Home Gym',
                          icon: Icons.fitness_center_outlined,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(state.homeGym ?? 'Not set', style: Theme.of(context).textTheme.bodyMedium),
                              ),
                              if (isEditing)
                                AdaptiveIconButton(
                                  onPressed: () => _pickHomeGym(context, ref),
                                  tooltip: 'Choose home gym',
                                  compact: true,
                                  icon: Icon(defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.search : Icons.search),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<Widget>(builder: (_) => const FollowersScreen()));
                    },
                    child: Text('Followers (${state.buddies.length})'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<Widget>(builder: (_) => const FollowingScreen()));
                    },
                    child: Text('Following (${state.buddies.length})'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Interests & Max difficulties
              Text('Interests & Max', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              _InterestsAndMax(editing: isEditing),
              if (isEditing) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AdaptiveFilledButton.icon(
                    onPressed: () => ref.read(_profileEditingProvider.notifier).state = false,
                    icon: Icon(defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle),
                    label: const Text('Done'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Week controls and summary moved from Home to Profile
              WeekHeader(
                weekStart: weekStart,
                onChange: (DateTime next) => ref.read(_profileWeekStartProvider.notifier).state = _startOfWeek(next),
              ),
              const SizedBox(height: AppSpacing.sm),
              WeeklySummaryCard(
                sessions: all,
                weekStart: weekStart,
                selectedType: selectedType,
                onTypeSelected: (ClimbType? t) => ref.read(_profileTypeFilterProvider.notifier).state = t,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 400,
                child: ActivityList(
                  items: weekSessions.map((Session s) => ActivityListItem(session: s)).toList(),
                  onTap: (Session s) {
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    vm.editPastSession(s.id);
                    Navigator.of(context).push(
                      MaterialPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.photoUrl, required this.initials, required this.isEditing, required this.onTap});
  final String? photoUrl;
  final String initials;
  final bool isEditing;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: (photoUrl == null || photoUrl!.isEmpty) ? null : NetworkImage(photoUrl!),
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? Text(initials, style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700))
              : null,
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(
                  isEditing ? (defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.photo_on_rectangle : Icons.photo_camera) : (defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.pencil : Icons.edit),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.icon});
  final String label;
  final Widget child;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: child),
      ],
    );
  }
}

class _InlineEditableText extends StatefulWidget {
  const _InlineEditableText({required this.value, required this.onChanged, this.hintText});
  final String value;
  final String? hintText;
  final ValueChanged<String> onChanged;
  @override
  State<_InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<_InlineEditableText> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _InlineEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextField(
      controller: _ctrl,
      labelText: widget.hintText,
      minLines: 1,
      maxLines: 1,
      onChanged: widget.onChanged,
    );
  }
}

String _initials(String name) {
  final List<String> parts = name.trim().split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
}

Future<void> _showPhotoActions(BuildContext context, WidgetRef ref) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: const Text('Profile Photo'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Placeholder: set a demo URL
              ref.read(profileProvider.notifier).updatePhotoUrl('https://avatars.githubusercontent.com/u/9919?s=200&v=4');
            },
            child: const Text('Upload photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(profileProvider.notifier).updatePhotoUrl(null);
            },
            isDestructiveAction: true,
            child: const Text('Remove photo'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: const Text('Profile Photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Upload photo'),
            onTap: () {
              Navigator.of(ctx).pop();
              ref.read(profileProvider.notifier).updatePhotoUrl('https://avatars.githubusercontent.com/u/9919?s=200&v=4');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Remove photo'),
            onTap: () {
              Navigator.of(ctx).pop();
              ref.read(profileProvider.notifier).updatePhotoUrl(null);
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
      ],
    ),
  );
}

Future<void> _pickHomeGym(BuildContext context, WidgetRef ref) async {
  final ProfileViewModel vm = ref.read(profileProvider.notifier);
  final String? gym = await showHomeGymPicker(context);
  if (gym != null) vm.updateHomeGym(gym);
}

DateTime _startOfWeek(DateTime d) {
  final DateTime date = DateTime(d.year, d.month, d.day);
  final int weekday = date.weekday;
  return date.subtract(Duration(days: weekday - 1));
}

DateTime _endOfWeek(DateTime start) => start.add(const Duration(days: 6));

class FollowersScreen extends ConsumerWidget {
  const FollowersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Buddy> buddies = ref.watch(profileProvider).buddies;
    return AdaptiveScaffold(
      title: const Text('Followers'),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: buddies.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int i) {
          final Buddy b = buddies[i];
          return ListTile(
            leading: CircleAvatar(child: Text(_initials(b.name))),
            title: Text(b.name),
          );
        },
      ),
    );
  }
}

class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Buddy> buddies = ref.watch(profileProvider).buddies;
    return AdaptiveScaffold(
      title: const Text('Following'),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: buddies.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int i) {
          final Buddy b = buddies[i];
          return ListTile(
            leading: CircleAvatar(child: Text(_initials(b.name))),
            title: Text(b.name),
          );
        },
      ),
    );
  }
}

class _InterestsAndMax extends ConsumerStatefulWidget {
  const _InterestsAndMax({required this.editing});
  final bool editing;
  @override
  ConsumerState<_InterestsAndMax> createState() => _InterestsAndMaxState();
}

class _InterestsAndMaxState extends ConsumerState<_InterestsAndMax> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileState ps = ref.watch(profileProvider);
    final ProfileViewModel vm = ref.read(profileProvider.notifier);
    final Set<ClimbType> interested = ps.interests;
    if (!widget.editing && interested.isEmpty) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'No interests set',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () => ref.read(_profileEditingProvider.notifier).state = true,
            child: const Text('Set interests'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!widget.editing)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (interested.contains(ClimbType.bouldering))
                _compactInterestPill(context, 'Bouldering', ps.maxGrades[ClimbType.bouldering]),
              if (interested.contains(ClimbType.topRope))
                _compactInterestPill(context, 'Top Rope', ps.maxGrades[ClimbType.topRope]),
              if (interested.contains(ClimbType.lead))
                _compactInterestPill(context, 'Lead', ps.maxGrades[ClimbType.lead]),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        if (widget.editing)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _interestItem(
                  context,
                  'Bouldering',
                  ps.maxGrades[ClimbType.bouldering],
                  selected: interested.contains(ClimbType.bouldering),
                  onToggle: () => vm.toggleInterest(ClimbType.bouldering),
                  onTap: () {
                    if (!interested.contains(ClimbType.bouldering)) vm.toggleInterest(ClimbType.bouldering);
                    _pickMaxGrade(context, ClimbType.bouldering, (String v) => vm.setMaxGrade(ClimbType.bouldering, v));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _interestItem(
                  context,
                  'Top Rope',
                  ps.maxGrades[ClimbType.topRope],
                  selected: interested.contains(ClimbType.topRope),
                  onToggle: () => vm.toggleInterest(ClimbType.topRope),
                  onTap: () {
                    if (!interested.contains(ClimbType.topRope)) vm.toggleInterest(ClimbType.topRope);
                    _pickMaxGrade(context, ClimbType.topRope, (String v) => vm.setMaxGrade(ClimbType.topRope, v));
                  },
                ),
              ),
              _interestItem(
                context,
                'Lead',
                ps.maxGrades[ClimbType.lead],
                selected: interested.contains(ClimbType.lead),
                onToggle: () => vm.toggleInterest(ClimbType.lead),
                onTap: () {
                  if (!interested.contains(ClimbType.lead)) vm.toggleInterest(ClimbType.lead);
                  _pickMaxGrade(context, ClimbType.lead, (String v) => vm.setMaxGrade(ClimbType.lead, v));
                },
              ),
            ],
          ),
      ],
    );
  }

  // removed unused _interestChip

  Future<void> _pickMaxGrade(BuildContext context, ClimbType type, ValueChanged<String> onPicked) async {
    final Widget picker = (type == ClimbType.bouldering)
        ? VGradePopupScrubber(
            onPicked: (Grade g) {
              onPicked(g.value);
              Navigator.of(context).pop();
            },
            vertical: true,
          )
        : YdsGradePopupScrubber(
            onPicked: (Grade g) {
              onPicked(g.value);
              Navigator.of(context).pop();
            },
            vertical: true,
          );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext ctx) {
        final ColorScheme scheme = Theme.of(ctx).colorScheme;
        final double height = MediaQuery.of(ctx).size.height * 0.6;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
            child: SizedBox(
              height: height,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Select grade', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(child: picker),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _interestItem(BuildContext context, String label, String? grade, {VoidCallback? onTap, VoidCallback? onToggle, bool selected = true}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool hasGrade = grade != null && grade.isNotEmpty;
  final TextStyle gradeStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
        color: hasGrade ? null : scheme.primary,
        fontStyle: hasGrade ? null : FontStyle.italic,
      );
  final Widget row = Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: selected ? 1.0 : 0.6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: scheme.outlineVariant, width: 1.5),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          height: 16,
          color: scheme.outlineVariant,
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: <Widget>[
                Text(
                  selected ? (hasGrade ? grade : 'Tap to set') : 'Hidden',
                  style: selected ? gradeStyle : Theme.of(context).textTheme.bodySmall!.copyWith(color: scheme.outline),
                ),
                if (onTap != null) ...<Widget>[
                  const SizedBox(width: 6),
                  Icon(defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.pencil : Icons.edit_outlined, size: 14, color: scheme.outline),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
  if (onTap == null) return row;
  if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
    return row;
  }
  return row;
}

Widget _compactInterestPill(BuildContext context, String label, String? grade) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final String display = (grade == null || grade.isEmpty) ? label : '$label | $grade';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: scheme.outlineVariant, width: 1),
    ),
    child: Text(display, style: Theme.of(context).textTheme.bodySmall),
  );
}
