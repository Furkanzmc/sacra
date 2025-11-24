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
final StateProvider<double?> _profileContentHeightProvider =
    StateProvider<double?>((StateProviderRef<double?> ref) => null);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  static final GlobalKey _profileKey = GlobalKey();

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
          child: Stack(
            children: <Widget>[
              // Background: Profile details
              SingleChildScrollView(
                padding: () {
                  final double bottomInset = MediaQuery.of(context).padding.bottom;
                  // Match the collapsed sheet height so background content can scroll fully above it
                  final double compactHeaderExtent = kMinInteractiveDimension + AppSpacing.md * 2 + AppSpacing.sm;
                  final double collapsedSheetHeight = AppSpacing.md +
                      _ActivitiesSheet._handleThickness +
                      AppSpacing.sm +
                      compactHeaderExtent +
                      AppSpacing.md +
                      bottomInset;
                  return EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    collapsedSheetHeight,
                  );
                }(),
                child: Container(
                  key: _profileKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (!isEditing)
                        Row(
                          children: <Widget>[
                            TextButton(
                              onPressed: () {
                                _showBuddiesSheet(context, 'Followers', state.buddies);
                              },
                              child: Text('Followers (${state.buddies.length})'),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            TextButton(
                              onPressed: () {
                                _showBuddiesSheet(context, 'Following', state.buddies);
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
                      // Social accounts
                      if (isEditing || ref.watch(profileProvider).socialLinks.isNotEmpty) ...<Widget>[
                        Text('Social', style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.sm),
                        _SocialLinks(editing: isEditing),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Note: Weekly summary and activities moved to the draggable sheet overlay
                    ],
                  ),
                ),
              ),
              // After first frame, measure and store profile content height
              Builder(
                builder: (BuildContext context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final BuildContext? c = _profileKey.currentContext;
                    if (c != null) {
                      final Size? sz = c.size;
                      if (sz != null) {
                        final double? current = ref.read(_profileContentHeightProvider);
                        if (current == null || (current - sz.height).abs() > 1.0) {
                          ref.read(_profileContentHeightProvider.notifier).state = sz.height;
                        }
                      }
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
              if (!isEditing)
                _ActivitiesSheet(
                  weekStart: weekStart,
                  allSessions: all,
                  weekSessions: weekSessions,
                  selectedType: selectedType,
                  onTypeSelected: (ClimbType? t) => ref.read(_profileTypeFilterProvider.notifier).state = t,
                  onOpenSession: (Session s) {
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    vm.editPastSession(s.id);
                    Navigator.of(context).push(
                      MaterialPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                    );
                  },
                  onWeekChange: (DateTime next) =>
                      ref.read(_profileWeekStartProvider.notifier).state = _startOfWeek(next),
                  initialCandidateFraction: () {
                    final double screenH = MediaQuery.of(context).size.height;
                    final double twoThirds = 2 / 3;
                    final double? ph = ref.watch(_profileContentHeightProvider);
                    if (ph == null || ph <= 0 || ph >= screenH) {
                      return twoThirds;
                    }
                    final double belowProfile = (1 - (ph / screenH)).clamp(0.1, 0.95);
                    // Start either at 2/3 or just below profile, whichever leaves more profile visible
                    return belowProfile < twoThirds ? belowProfile : twoThirds;
                  }(),
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

// Draggable activities + weekly stats sheet that can cover profile when expanded
class _ActivitiesSheet extends StatefulWidget {
  const _ActivitiesSheet({
    required this.weekStart,
    required this.allSessions,
    required this.weekSessions,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onOpenSession,
    required this.onWeekChange,
    required this.initialCandidateFraction,
  });
  final DateTime weekStart;
  final List<Session> allSessions;
  final List<Session> weekSessions;
  final ClimbType? selectedType;
  final ValueChanged<ClimbType?> onTypeSelected;
  final ValueChanged<Session> onOpenSession;
  final ValueChanged<DateTime> onWeekChange;
  final double initialCandidateFraction;

  static const double _handleThickness = 5.0;
  static const double _handleWidth = 36.0;
  static const double _cornerRadius = 16.0;
  static const double _weeklySummaryCardHeight = 140.0; // Must match WeeklySummaryCard's SizedBox height

  @override
  State<_ActivitiesSheet> createState() => _ActivitiesSheetState();
}

class _ActivitiesSheetState extends State<_ActivitiesSheet> {
  late final DraggableScrollableController _dragCtrl;
  @override
  void initState() {
    super.initState();
    _dragCtrl = DraggableScrollableController();
    _dragCtrl.addListener(() {
      if (!mounted) return;
      // Defer state updates to the end of the current frame to avoid re-entrant build/layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    // Compact header extent (summary row + vertical padding)
    final double compactHeaderExtent = kMinInteractiveDimension + AppSpacing.md * 2 + AppSpacing.sm;
    // Compute collapsed height using a compact header (summary)
    final double collapsedHeight =
        // top padding
        AppSpacing.md +
        // handle
        _ActivitiesSheet._handleThickness + AppSpacing.sm +
        // compact header extent
        compactHeaderExtent +
        // outer padding and safe area
        AppSpacing.md +
        bottomInset;
    final double minFractionComputed = (collapsedHeight / screen.height).clamp(0.2, 0.95);
    // Pick starting size: either 2/3 (passed in) or just below profile content, but not below collapsed minimum
    final double initialFraction = widget.initialCandidateFraction.clamp(minFractionComputed, 1.0);
    // Allow dragging lower than initial down to minFractionComputed
    final double minFraction = minFractionComputed;

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      controller: _dragCtrl,
      minChildSize: minFraction,
      initialChildSize: initialFraction,
      maxChildSize: 1.0,
      snap: true,
      builder: (BuildContext context, ScrollController listController) {
        bool isCompact = false;
        try {
          final double sz = _dragCtrl.size;
          // Treat sizes within ~5% of minChildSize as collapsed to ensure summary appears reliably
          isCompact = (sz - minFraction) <= 0.05;
        } catch (_) {
          // Controller not yet attached; default to full header.
          isCompact = false;
        }
        void applyHeaderPan(DragUpdateDetails details) {
          final double delta = details.delta.dy;
          if (delta == 0) return;
          try {
            final double current = _dragCtrl.size;
            final double newSize = (current - delta / screen.height).clamp(minFraction, 1.0);
            if (newSize != current) {
              _dragCtrl.jumpTo(newSize);
            }
          } catch (_) {/* ignore if not attached */}
        }
        // Compute weekly stats for compact summary
        int total = 0, boulder = 0, ropeTop = 0, ropeLead = 0;
        final DateTime weekEnd = _endOfWeek(widget.weekStart);
        for (final Session s in widget.allSessions) {
          final DateTime dt = s.endTime ?? s.startTime;
          final DateTime d = DateTime(dt.year, dt.month, dt.day);
          if (!d.isBefore(widget.weekStart) && !d.isAfter(weekEnd)) {
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
        final double fullHeaderExtent = kMinInteractiveDimension + AppSpacing.sm + _ActivitiesSheet._weeklySummaryCardHeight + AppSpacing.md * 3 + AppSpacing.sm;
        return Material(
          elevation: 8,
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(_ActivitiesSheet._cornerRadius)),
          child: SafeArea(
            top: false,
            bottom: true,
            child: CustomScrollView(
              controller: listController,
              slivers: <Widget>[
              // Handle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                  child: Center(
                    child: Container(
                      width: _ActivitiesSheet._handleWidth,
                      height: _ActivitiesSheet._handleThickness,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              // Draggable header (pinned), swaps compact/full
              SliverPersistentHeader(
                pinned: true,
                delegate: _SheetHeaderDelegate(
                  minExtentHeight: isCompact ? compactHeaderExtent : fullHeaderExtent,
                  maxExtentHeight: isCompact ? compactHeaderExtent : fullHeaderExtent,
                  builder: (BuildContext context) {
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: applyHeaderPan,
                      child: SizedBox.expand(
                        child: Container(
                          color: scheme.surface,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: isCompact
                              ? _CompactWeeklySummary(total: total, boulder: boulder, ropeTop: ropeTop, ropeLead: ropeLead)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: WeekHeader(
                                        weekStart: widget.weekStart,
                                        onChange: widget.onWeekChange,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                      child: WeeklySummaryCard(
                                        sessions: widget.allSessions,
                                        weekStart: widget.weekStart,
                                        selectedType: widget.selectedType,
                                        onTypeSelected: widget.onTypeSelected,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Activities list (hidden when compact)
              if (!isCompact)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  sliver: widget.weekSessions.isEmpty
                      ? const SliverToBoxAdapter(child: Center(child: Text('No sessions')))
                      : SliverList.separated(
                          itemCount: widget.weekSessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) {
                            final Session s = widget.weekSessions[index];
                            final DateTime recorded = s.endTime ?? s.startTime;
                            final String date = adaptiveFormatDate(context, recorded);
                            final String time = adaptiveFormatTime(context, recorded);
                            final int count = s.attempts.length;
                            final _SheetTypeColors tc = _sheetColorsForType(s.climbType, scheme);
                            final String? emoji = _ratingEmojiLocal(s.rating);
                            return AdaptiveCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              color: tc.container,
                              onTap: () => widget.onOpenSession(s),
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
                                              Text(_activityTypeLabelLocal(s.climbType),
                                                  style: AppTextStyles.title.copyWith(color: tc.onContainer)),
                                              if (emoji != null) ...<Widget>[
                                                const SizedBox(width: 6),
                                                Text(emoji),
                                              ],
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
                        ),
                ),
                // Always reserve safe area bottom
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SheetHeaderDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.builder,
  });
  final double minExtentHeight;
  final double maxExtentHeight;
  final WidgetBuilder builder;

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => builder(context);

  @override
  bool shouldRebuild(covariant _SheetHeaderDelegate oldDelegate) {
    return minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight ||
        builder != oldDelegate.builder;
  }
}

class _CompactWeeklySummary extends StatelessWidget {
  const _CompactWeeklySummary({
    required this.total,
    required this.boulder,
    required this.ropeTop,
    required this.ropeLead,
  });
  final int total;
  final int boulder;
  final int ropeTop;
  final int ropeLead;
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle? labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600);
    Widget pill(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: scheme.onSurface),
            const SizedBox(width: 6),
            Text(text, style: labelStyle),
          ],
        ),
      );
    }

    return SizedBox(
      height: kMinInteractiveDimension + AppSpacing.md,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.timeline, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('This week: $total', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              pill(Icons.terrain, 'Bouldering $boulder'),
              pill(Icons.safety_check, 'Top Rope $ropeTop'),
              pill(Icons.route, 'Lead $ropeLead'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetTypeColors {
  const _SheetTypeColors(this.container, this.onContainer, this.icon);
  final Color container;
  final Color onContainer;
  final IconData icon;
}

_SheetTypeColors _sheetColorsForType(ClimbType t, ColorScheme scheme) {
  switch (t) {
    case ClimbType.bouldering:
      return _SheetTypeColors(scheme.secondaryContainer, scheme.onSecondaryContainer, Icons.terrain);
    case ClimbType.topRope:
      return _SheetTypeColors(scheme.tertiaryContainer, scheme.onTertiaryContainer, Icons.safety_check);
    case ClimbType.lead:
      return _SheetTypeColors(scheme.primaryContainer, scheme.onPrimaryContainer, Icons.route);
  }
}

String _activityTypeLabelLocal(ClimbType t) {
  switch (t) {
    case ClimbType.bouldering:
      return 'Bouldering';
    case ClimbType.topRope:
      return 'Top Rope';
    case ClimbType.lead:
      return 'Leading';
  }
}

String? _ratingEmojiLocal(int? rating) {
  switch (rating) {
    case 1:
      return '😫';
    case 2:
      return '😕';
    case 3:
      return '😐';
    case 4:
      return '🙂';
    case 5:
      return '😄';
    default:
      return null;
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
        // Reduce top padding if there are many items to maximize visible content
        // Approximate counts for grade sets
        final int itemCount = (type == ClimbType.bouldering) ? 17 : 31;
        final bool many = itemCount > 10;
        final double topGap = many ? 6 : 12;
        final EdgeInsets contentPadding = EdgeInsets.fromLTRB(AppSpacing.md, many ? AppSpacing.sm : AppSpacing.md, AppSpacing.md, AppSpacing.md);
        return SafeArea(
          child: Padding(
            padding: contentPadding,
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
                  SizedBox(height: topGap),
                  Text('Select grade', style: Theme.of(ctx).textTheme.titleMedium),
                  SizedBox(height: many ? 4 : 8),
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

class _SocialLinks extends ConsumerStatefulWidget {
  const _SocialLinks({required this.editing});
  final bool editing;
  @override
  ConsumerState<_SocialLinks> createState() => _SocialLinksState();
}

class _SocialLinksState extends ConsumerState<_SocialLinks> {
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _tiktokCtrl;
  late final TextEditingController _youtubeCtrl;
  late final TextEditingController _xCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final Map<String, String> links = ref.read(profileProvider).socialLinks;
    _instagramCtrl = TextEditingController(text: links['instagram'] ?? '');
    _tiktokCtrl = TextEditingController(text: links['tiktok'] ?? '');
    _youtubeCtrl = TextEditingController(text: links['youtube'] ?? '');
    _xCtrl = TextEditingController(text: links['x'] ?? '');
    _websiteCtrl = TextEditingController(text: links['website'] ?? '');
  }

  @override
  void didUpdateWidget(covariant _SocialLinks oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Map<String, String> links = ref.read(profileProvider).socialLinks;
    if (_instagramCtrl.text != (links['instagram'] ?? '')) _instagramCtrl.text = links['instagram'] ?? '';
    if (_tiktokCtrl.text != (links['tiktok'] ?? '')) _tiktokCtrl.text = links['tiktok'] ?? '';
    if (_youtubeCtrl.text != (links['youtube'] ?? '')) _youtubeCtrl.text = links['youtube'] ?? '';
    if (_xCtrl.text != (links['x'] ?? '')) _xCtrl.text = links['x'] ?? '';
    if (_websiteCtrl.text != (links['website'] ?? '')) _websiteCtrl.text = links['website'] ?? '';
  }

  @override
  void dispose() {
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _youtubeCtrl.dispose();
    _xCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileState ps = ref.watch(profileProvider);
    final ProfileViewModel vm = ref.read(profileProvider.notifier);
    if (!widget.editing) {
      if (ps.socialLinks.isEmpty) {
        return const SizedBox.shrink();
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ps.socialLinks.entries
            .map((MapEntry<String, String> e) => _socialPill(context, _labelFor(e.key), e.value))
            .toList(),
      );
    }
    return Column(
      children: <Widget>[
        _LabeledField(
          label: 'Instagram',
          icon: Icons.camera_alt_outlined,
          child: AdaptiveTextField(
            controller: _instagramCtrl,
            labelText: '@handle',
            onChanged: (String v) => vm.updateSocialLink('instagram', v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LabeledField(
          label: 'TikTok',
          icon: Icons.music_note,
          child: AdaptiveTextField(
            controller: _tiktokCtrl,
            labelText: '@handle',
            onChanged: (String v) => vm.updateSocialLink('tiktok', v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LabeledField(
          label: 'YouTube',
          icon: Icons.ondemand_video_outlined,
          child: AdaptiveTextField(
            controller: _youtubeCtrl,
            labelText: 'channel or url',
            onChanged: (String v) => vm.updateSocialLink('youtube', v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LabeledField(
          label: 'X',
          icon: Icons.alternate_email,
          child: AdaptiveTextField(
            controller: _xCtrl,
            labelText: '@handle',
            onChanged: (String v) => vm.updateSocialLink('x', v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LabeledField(
          label: 'Website',
          icon: Icons.link,
          child: AdaptiveTextField(
            controller: _websiteCtrl,
            labelText: 'https://example.com',
            onChanged: (String v) => vm.updateSocialLink('website', v),
          ),
        ),
      ],
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case 'instagram':
        return 'Instagram';
      case 'tiktok':
        return 'TikTok';
      case 'youtube':
        return 'YouTube';
      case 'x':
        return 'X';
      case 'website':
        return 'Website';
      default:
        return key;
    }
  }
}

Widget _socialPill(BuildContext context, String label, String value) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: scheme.outlineVariant, width: 1),
    ),
    child: Text('$label | $value', style: Theme.of(context).textTheme.bodySmall),
  );
}
Future<void> _showBuddiesSheet(BuildContext context, String title, List<Buddy> buddies) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) {
      final ColorScheme scheme = Theme.of(ctx).colorScheme;
      final double height = MediaQuery.of(ctx).size.height * 0.6;
      final bool many = buddies.length > 10;
      final EdgeInsets contentPadding = EdgeInsets.all(many ? AppSpacing.sm : AppSpacing.md);
      return SafeArea(
        child: Padding(
          padding: contentPadding,
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: many ? 6 : 12),
                Text(title, style: Theme.of(ctx).textTheme.titleMedium, textAlign: TextAlign.center),
                SizedBox(height: many ? 4 : 8),
                Expanded(
                  child: ListView.separated(
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
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
