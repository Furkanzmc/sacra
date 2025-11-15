// removed unused math import
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/session.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/v_grade_scrubber.dart';
import '../widgets/adaptive.dart';
import '../widgets/navigation_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MountainHeightView extends StatefulWidget {
  const _MountainHeightView({required this.heightMeters, required this.maxHeightMeters, this.onChanged});

  final double heightMeters;
  final double maxHeightMeters;
  final void Function(double v)? onChanged;

  @override
  State<_MountainHeightView> createState() => _MountainHeightViewState();
}

class _MountainHeightViewState extends State<_MountainHeightView> {
  double? _pressOffsetFromCenterY;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _MountainPainter(color: scheme.surfaceContainerHighest.withValues(alpha: 1.0), lineColor: scheme.outlineVariant),
            child: const SizedBox.expand(),
          ),
          // indicator line/dot
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final BuildContext lbContext = context;
              final double h = constraints.maxHeight;
              const double apexFraction = 0.2; // keep in sync with painter apex
              final double apexY = h * apexFraction;
              const double pointerVisualH = 12.0; // actual painted arrow height (fixed)
              final double baseHalfVisual = pointerVisualH / 3; // triangle half-thickness
              final double bottomSafe = h - (baseHalfVisual + 1.0); // ensure full triangle is visible above baseline
              final double clamped = (widget.heightMeters / (widget.maxHeightMeters == 0 ? 1 : widget.maxHeightMeters)).clamp(0.0, 1.0);
              final double centerX = constraints.maxWidth / 2;
              const double pointerLength = 12.0; // horizontal length of pointer triangle
              const double pointerHitWidth = 40.0; // wider hit target without changing visuals
              const double pointerHitH = 40.0; // taller hit height so bottom is fully grabbable
              return Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: constraints.maxWidth / 2 - 1,
                    top: apexY,
                    bottom: 0,
                    child: Container(width: 2, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  // Painted triangular pointer; tip aligns exactly with mountain center line
                  Positioned(
                    top: () {
                      final double tipY = apexY + (1 - clamped) * (bottomSafe - apexY);
                      double top = tipY - (pointerHitH / 2);
                      // Keep hitbox fully inside
                      top = top.clamp(0.0, bottomSafe - pointerHitH);
                      // Ensure the painted arrow (with baseHalf = pointerVisualH/3) fully fits inside the hitbox
                      final double baseHalf = baseHalfVisual;
                      final double margin = baseHalf + 1.0; // +1 px to avoid visual clipping
                      double tipWithin = tipY - top;
                      if (tipWithin < margin) {
                        top = (tipY - margin).clamp(0.0, bottomSafe - pointerHitH);
                      } else if (tipWithin > pointerHitH - margin) {
                        top = (tipY - (pointerHitH - margin)).clamp(0.0, bottomSafe - pointerHitH);
                      }
                      return top;
                    }(),
                    // Place the hitbox so its right edge sits exactly on the center line
                    left: centerX - pointerHitWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (DragStartDetails d) {
                        final RenderBox box = lbContext.findRenderObject() as RenderBox;
                        final Offset local = box.globalToLocal(d.globalPosition);
                        final double tipY = apexY + (1 - clamped) * (bottomSafe - apexY);
                        setState(() {
                          _pressOffsetFromCenterY = local.dy - tipY;
                        });
                      },
                      onVerticalDragUpdate: (DragUpdateDetails d) {
                        if (widget.onChanged == null) return;
                        final RenderBox box = lbContext.findRenderObject() as RenderBox;
                        final Offset local = box.globalToLocal(d.globalPosition);
                        final double desiredTipY = (local.dy - (_pressOffsetFromCenterY ?? 0.0)).clamp(apexY, bottomSafe);
                        final double ratio = (1 - ((desiredTipY - apexY) / (bottomSafe - apexY))).clamp(0.0, 1.0);
                        widget.onChanged!(ratio * widget.maxHeightMeters);
                      },
                      onVerticalDragEnd: (_) {
                        setState(() {
                          _pressOffsetFromCenterY = null;
                        });
                      },
                      child: Builder(
                        builder: (BuildContext context) {
                          // Recompute to supply painter with the tip position inside hitbox
                          final double tipY = apexY + (1 - clamped) * (bottomSafe - apexY);
                          final RenderBox? rb = context.findRenderObject() as RenderBox?;
                          // Estimate top we set above (if rb not ready, fallback)
                          double topEst = 0;
                          if (rb != null) {
                            final Offset off = rb.localToGlobal(Offset.zero) - (lbContext.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
                            topEst = off.dy;
                          } else {
                            double t = tipY - (pointerHitH / 2);
                            if (t < 0) t = 0;
                            final double maxTop = h - pointerHitH;
                            if (t > maxTop) t = maxTop;
                            topEst = t;
                          }
                          final double tipWithin = (tipY - topEst).clamp(0.0, pointerHitH - 1.0); // bias 1px from bottom to avoid clip
                          return SizedBox(
                            width: pointerHitWidth,
                            height: pointerHitH,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: pointerLength,
                                height: pointerHitH,
                                child: CustomPaint(
                                  painter: _RightPointerPainter(color: scheme.primary, tipYWithin: tipWithin, visualHeight: pointerVisualH),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // pointer is the only affordance; value displayed elsewhere in the card
        ],
      ),
    );
  }
}

class _RightPointerPainter extends CustomPainter {
  _RightPointerPainter({required this.color, this.tipYWithin, this.visualHeight});

  final Color color;
  final double? tipYWithin; // optional position of the tip within the given height, to center the triangle
  final double? visualHeight; // optional fixed height for the triangle

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    // Draw a right-pointing isosceles triangle; tip at right edge
    final double tipX = size.width;
    final double tipY = (tipYWithin != null)
        ? tipYWithin!.clamp(0.0, size.height)
        : (size.height / 2);
    final double baseX = 0;
    final double h = visualHeight != null ? visualHeight!.clamp(2.0, size.height) : size.height;
    final double baseHalf = h / 3; // slender pointer

    final double topY = (tipY - baseHalf).clamp(0.0, size.height);
    final double bottomY = (tipY + baseHalf).clamp(0.0, size.height);

    path.moveTo(baseX, topY);
    path.lineTo(baseX, bottomY);
    path.lineTo(tipX, tipY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RightPointerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.tipYWithin != tipYWithin || oldDelegate.visualHeight != visualHeight;
  }
}

class _MountainPainter extends CustomPainter {
  _MountainPainter({required this.color, required this.lineColor});

  final Color color;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = color;
    final Path path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.25, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.75, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, p);
    final Paint border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = lineColor.withValues(alpha: 0.6);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
 
IconData _adaptiveStopIcon() {
  return (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
      ? CupertinoIcons.stop_fill
      : Icons.stop;
}

IconData _adaptiveAddIcon() {
  return (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
      ? CupertinoIcons.add
      : Icons.add;
}

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key, this.session});

  final Session? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionLogState state = ref.watch(sessionLogProvider);
    final Session? effectiveSession = session ?? state.activeSession;
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);

    // Compute friendly title and optional highest grade (bouldering)
    String displayType;
    switch (effectiveSession?.climbType) {
      case ClimbType.bouldering:
        displayType = 'Bouldering';
        break;
      case ClimbType.topRope:
        displayType = 'Top rope';
        break;
      case ClimbType.lead:
        displayType = 'Lead';
        break;
      default:
        displayType = 'Session';
    }
    return AdaptiveScaffold(
      title: Text(
        effectiveSession == null ? 'Active Session' : 'Active: $displayType',
        style: AppTextStyles.title,
      ),
      actions: (session != null)
          ? null // viewing/editing a past session; no end button
          : (effectiveSession == null
              ? null
              : <Widget>[
        AdaptiveIconButton(
          onPressed: () async {
            final bool confirmed = await _confirmEndSession(context);
            if (!confirmed) return;
            vm.endSession();
            // On iOS, if presented modally (fullscreenDialog), pop the sheet.
            if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
            } else {
              final NavigationScope? scope = NavigationScope.of(context);
              scope?.setTab(0);
            }
            },
            tooltip: 'End Session',
          icon: Icon(_adaptiveStopIcon()),
          ),
              ])
          ,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.constrainedWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: effectiveSession == null
                ? _StartOptions(onStart: vm.startSession)
                : _ActiveBody(session: effectiveSession),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmEndSession(BuildContext context) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return await showCupertinoDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => CupertinoAlertDialog(
            title: const Text('End session?'),
            content: const Text('This will stop tracking the current session.'),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(false),
                isDefaultAction: true,
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(true),
                isDestructiveAction: true,
                child: const Text('End'),
              ),
            ],
          ),
        ) ??
        false;
  }
  return await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('End session?'),
          content: const Text('This will stop tracking the current session.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('End')),
          ],
        ),
      ) ??
      false;
}

final StateProvider<bool> sessionNotesVisibleProvider = StateProvider<bool>((StateProviderRef<bool> ref) => false);

class _ActiveBody extends ConsumerWidget {
  const _ActiveBody({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
        Text(
          adaptiveFormatTime(context, session.startTime),
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _SessionNotesField(),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _AttemptsList(attempts: session.attempts),
        ),
          const SizedBox(height: AppSpacing.md),
        SafeArea(
          top: false,
          child: _TypeAwareAttemptComposer(
            type: session.climbType,
            onAdd: vm.addAttempt,
          ),
        ),
      ],
    );
  }
}

class _SessionNotesButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session? s = ref.watch(sessionLogProvider).activeSession ?? ref.watch(sessionLogProvider).editingSession;
    final bool has = (s?.notes ?? '').isNotEmpty;
    final bool show = ref.watch(sessionNotesVisibleProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        AdaptiveIconButton(
          onPressed: () => ref.read(sessionNotesVisibleProvider.notifier).state = !show,
          icon: Icon(
            defaultTargetPlatform == TargetPlatform.iOS
                ? (show ? CupertinoIcons.doc_text : CupertinoIcons.text_alignleft)
                : (show ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined),
            color: show ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        if (has && !show)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

class _SessionNotesField extends ConsumerStatefulWidget {
  const _SessionNotesField();

  @override
  ConsumerState<_SessionNotesField> createState() => _SessionNotesFieldState();
}

class _SessionNotesFieldState extends ConsumerState<_SessionNotesField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final Session? s = ref.read(sessionLogProvider).activeSession ?? ref.read(sessionLogProvider).editingSession;
    _controller = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _SessionNotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Session? s = ref.read(sessionLogProvider).activeSession ?? ref.read(sessionLogProvider).editingSession;
    final String next = s?.notes ?? '';
    if (_controller.text != next) {
      // Preserve caret at end when external value changes
      _controller.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool show = ref.watch(sessionNotesVisibleProvider);
    return AnimatedCrossFade(
      crossFadeState: show ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 200),
      firstChild: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: AdaptiveTextField(
          controller: _controller,
          labelText: 'Session notes',
          minLines: 1,
          maxLines: 3,
          onChanged: (String v) => ref.read(sessionLogProvider.notifier).updateSessionNotes(v.isEmpty ? null : v),
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }
}

class _TypeAwareAttemptComposer extends StatefulWidget {
  const _TypeAwareAttemptComposer({
    required this.type,
    required this.onAdd,
  });

  final ClimbType type;
  final void Function(ClimbAttempt attempt) onAdd;

  @override
  State<_TypeAwareAttemptComposer> createState() => _TypeAwareAttemptComposerState();
}

class _TypeAwareAttemptComposerState extends State<_TypeAwareAttemptComposer> {
  final TextEditingController _gradeCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  bool _completed = false;

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Add Attempt'),
          const SizedBox(height: AppSpacing.sm),
          if (widget.type == ClimbType.bouldering)
            VGradePopupScrubber(
              onPicked: (Grade g) {
                _gradeCtrl.text = g.value;
                _onAdd();
              },
              trailing: _SessionNotesButton(),
            )
          else if (widget.type == ClimbType.topRope || widget.type == ClimbType.lead)
            YdsGradePopupScrubber(
              onPicked: (Grade g) {
                _gradeCtrl.text = g.value;
                _onAdd();
              },
              trailing: _SessionNotesButton(),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _gradeCtrl,
                    decoration: const InputDecoration(labelText: 'Grade'),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _heightCtrl,
                    decoration: const InputDecoration(labelText: 'Height (m)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AdaptiveSwitch(
                      value: _completed,
                      onChanged: (bool v) => setState(() => _completed = v),
                    ),
                    const Text('Completed'),
                  ],
                ),
                AdaptiveFilledButton.icon(
                  onPressed: _onAdd,
                  icon: Icon(_adaptiveAddIcon()),
                  label: const Text('Add'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _onAdd() {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime now = DateTime.now();
    final Grade grade = Grade(system: GradeSystem.vScale, value: _gradeCtrl.text.isEmpty ? 'V0' : _gradeCtrl.text);

    switch (widget.type) {
      case ClimbType.bouldering:
        widget.onAdd(
          BoulderingAttempt(
            id: id,
            timestamp: now,
            grade: grade,
            sent: _completed,
            completed: _completed,
            attemptNumber: 1,
          ),
        );
        break;
      case ClimbType.topRope:
        final double height = double.tryParse(_heightCtrl.text) ?? 0;
        widget.onAdd(
          TopRopeAttempt(
            id: id,
            timestamp: now,
            grade: Grade(system: GradeSystem.yds, value: _gradeCtrl.text.isEmpty ? '5.8' : _gradeCtrl.text),
            heightMeters: height,
            falls: 0,
            completed: _completed,
            sent: false,
            attemptNumber: 1,
          ),
        );
        break;
      case ClimbType.lead:
        final double height = double.tryParse(_heightCtrl.text) ?? 0;
        widget.onAdd(
          LeadAttempt(
            id: id,
            timestamp: now,
            grade: Grade(system: GradeSystem.yds, value: _gradeCtrl.text.isEmpty ? '5.10a' : _gradeCtrl.text),
            heightMeters: height,
            falls: 0,
            completed: _completed,
          ),
        );
        break;
    }

    _completed = false;
    _heightCtrl.clear();
    _gradeCtrl.clear();
    setState(() {});
  }
}

class _AttemptsList extends ConsumerWidget {
  const _AttemptsList({required this.attempts});

  final List<ClimbAttempt> attempts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (attempts.isEmpty) {
      return const _EmptyAttempts();
    }
    return ListView.separated(
      itemCount: attempts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final int reversedIndex = attempts.length - 1 - index;
        final ClimbAttempt a = attempts[reversedIndex];
        final int displayNumber = reversedIndex + 1; // total climbs up to this attempt
        int? perProblemAttempt;
        if (a is BoulderingAttempt) {
          final String keyGrade = a.grade.value;
          int count = 0;
          for (int i = 0; i <= reversedIndex; i++) {
            final ClimbAttempt prev = attempts[i];
            if (prev is BoulderingAttempt && prev.grade.value == keyGrade) {
              count++;
            }
          }
          perProblemAttempt = count;
        }
        return _AttemptCard(a, displayNumber, perProblemAttempt: perProblemAttempt);
      },
    );
  }
}

class _AttemptCard extends ConsumerStatefulWidget {
  const _AttemptCard(this.a, this.number, {this.perProblemAttempt});

  final ClimbAttempt a;
  final int number;
  final int? perProblemAttempt;

  @override
  ConsumerState<_AttemptCard> createState() => _AttemptCardState();
}

class _AttemptCardState extends ConsumerState<_AttemptCard> with AutomaticKeepAliveClientMixin<_AttemptCard> {
  late bool _showNotes = ((widget.a.notes) ?? '').isNotEmpty;
  bool _showHeight = false;
  bool? _sentLocal;
  bool? _completedLocal;
  bool? _ropeSentLocal;
  bool? _ropeCompletedLocal;
  double? _attemptDragStartX;
  double _attemptDragProgress = 0; // 0..1
  int _attemptDragDir = 0; // -1 left, 1 right, 0 none
  double _attemptPillWidth = 120;
  double _hintOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.a is BoulderingAttempt) {
      _sentLocal = (widget.a as BoulderingAttempt).sent;
      _completedLocal = (widget.a as BoulderingAttempt).isCompleted;
    } else if (widget.a is TopRopeAttempt) {
      _ropeSentLocal = (widget.a as TopRopeAttempt).isSent;
      _ropeCompletedLocal = (widget.a as TopRopeAttempt).completed;
    } else if (widget.a is LeadAttempt) {
      _ropeSentLocal = (widget.a as LeadAttempt).isSent;
      _ropeCompletedLocal = (widget.a as LeadAttempt).completed;
    }
    // One-shot hint pulse on Material platforms
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      Future.microtask(() async {
        if (!mounted) return;
        setState(() => _hintOpacity = 0.0);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
        setState(() => _hintOpacity = 1.0);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        setState(() => _hintOpacity = 0.6);
      });
    }
  }

  // second initState removed (duplicate)

  @override
  void didUpdateWidget(covariant _AttemptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.a is BoulderingAttempt) {
      _sentLocal = (widget.a as BoulderingAttempt).sent;
      _completedLocal = (widget.a as BoulderingAttempt).isCompleted;
      _ropeSentLocal = null;
      _ropeCompletedLocal = null;
    } else {
      _sentLocal = null;
      if (widget.a is TopRopeAttempt) {
        _ropeSentLocal = (widget.a as TopRopeAttempt).isSent;
        _ropeCompletedLocal = (widget.a as TopRopeAttempt).completed;
      } else if (widget.a is LeadAttempt) {
        _ropeSentLocal = (widget.a as LeadAttempt).isSent;
        _ropeCompletedLocal = (widget.a as LeadAttempt).completed;
      } else {
        _ropeSentLocal = null;
        _ropeCompletedLocal = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool showHeight = _showHeight;
    late final String title;
    if (widget.a is BoulderingAttempt) {
      final BoulderingAttempt b = widget.a as BoulderingAttempt;
      title = b.grade.value;
    } else if (widget.a is TopRopeAttempt) {
      final TopRopeAttempt t = widget.a as TopRopeAttempt;
      title = t.grade.value;
    } else if (widget.a is LeadAttempt) {
      final LeadAttempt l = widget.a as LeadAttempt;
      title = l.grade.value;
    } else {
      title = 'Attempt';
    }

    final bool hasNotes = ((widget.a.notes) ?? '').isNotEmpty;

    return AdaptiveCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.a is BoulderingAttempt || widget.a is TopRopeAttempt || widget.a is LeadAttempt)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Problem number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('#${widget.number}'),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Flashed (Bouldering) / Sent (Rope)
                AdaptiveIconButton(
                  onPressed: () {
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    if (widget.a is BoulderingAttempt) {
                      final BoulderingAttempt b = widget.a as BoulderingAttempt;
                      final bool next = !(_sentLocal ?? b.sent);
                      setState(() => _sentLocal = next);
                      vm.updateBoulderAttemptSent(b.id, next);
                      if (next) {
                        _completedLocal = true;
                        vm.updateBoulderAttemptCompleted(b.id, true);
                      }
                    } else if (widget.a is TopRopeAttempt) {
                      final TopRopeAttempt t = widget.a as TopRopeAttempt;
                      final bool next = !(_ropeSentLocal ?? t.isSent);
                      setState(() => _ropeSentLocal = next);
                      vm.updateTopRopeAttemptSent(t.id, next);
                    } else if (widget.a is LeadAttempt) {
                      final LeadAttempt l = widget.a as LeadAttempt;
                      final bool next = !(_ropeSentLocal ?? l.isSent);
                      setState(() => _ropeSentLocal = next);
                      vm.updateLeadAttemptSent(l.id, next);
                    }
                  },
                  tooltip: (widget.a is BoulderingAttempt) ? 'Flashed' : 'Sent',
                  icon: Icon(
                    () {
                      if (widget.a is BoulderingAttempt) {
                        final bool on = (_sentLocal ?? (widget.a as BoulderingAttempt).sent);
                        return defaultTargetPlatform == TargetPlatform.iOS
                            ? (on ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt)
                            : (on ? Icons.bolt : Icons.bolt_outlined);
                      }
                      // Rope uses a flag icon for Sent
                      return defaultTargetPlatform == TargetPlatform.iOS
                          ? (((widget.a is TopRopeAttempt ? (_ropeSentLocal ?? (widget.a as TopRopeAttempt).isSent) : (_ropeSentLocal ?? (widget.a as LeadAttempt).isSent)))
                              ? CupertinoIcons.flag_fill
                              : CupertinoIcons.flag)
                          : (((widget.a is TopRopeAttempt ? (_ropeSentLocal ?? (widget.a as TopRopeAttempt).isSent) : (_ropeSentLocal ?? (widget.a as LeadAttempt).isSent)))
                              ? Icons.flag
                              : Icons.outlined_flag);
                    }(),
                    color: () {
                      if (widget.a is BoulderingAttempt) {
                        return (_sentLocal ?? (widget.a as BoulderingAttempt).sent) ? Theme.of(context).colorScheme.primary : null;
                      }
                      if (widget.a is TopRopeAttempt) {
                        return ((_ropeSentLocal ?? (widget.a as TopRopeAttempt).isSent)) ? Theme.of(context).colorScheme.primary : null;
                      }
                      return ((_ropeSentLocal ?? (widget.a as LeadAttempt).isSent)) ? Theme.of(context).colorScheme.primary : null;
                    }(),
                  ),
                ),
                if (widget.a is BoulderingAttempt)
                  AdaptiveIconButton(
                    onPressed: () {
                      final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                      final BoulderingAttempt b = widget.a as BoulderingAttempt;
                      final bool next = !(_completedLocal ?? b.isCompleted);
                      setState(() => _completedLocal = next);
                      vm.updateBoulderAttemptCompleted(b.id, next);
                    },
                    tooltip: 'Completed',
                    icon: Icon(
                      defaultTargetPlatform == TargetPlatform.iOS
                          ? (((_completedLocal ?? (widget.a as BoulderingAttempt).isCompleted)) ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.check_mark_circled)
                          : (((_completedLocal ?? (widget.a as BoulderingAttempt).isCompleted)) ? Icons.check_circle : Icons.check_circle_outline),
                      color: ((_completedLocal ?? (widget.a as BoulderingAttempt).isCompleted)) ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                if (widget.a is TopRopeAttempt || widget.a is LeadAttempt)
                  AdaptiveIconButton(
                    onPressed: () {
                      final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                      if (widget.a is TopRopeAttempt) {
                        final TopRopeAttempt t = widget.a as TopRopeAttempt;
                        final bool next = !(_ropeCompletedLocal ?? t.completed);
                        setState(() => _ropeCompletedLocal = next);
                        vm.updateTopRopeAttemptCompleted(t.id, next);
                      } else {
                        final LeadAttempt l = widget.a as LeadAttempt;
                        final bool next = !(_ropeCompletedLocal ?? l.completed);
                        setState(() => _ropeCompletedLocal = next);
                        vm.updateLeadAttemptCompleted(l.id, next);
                      }
                    },
                    tooltip: 'Completed',
                    icon: Icon(
                      defaultTargetPlatform == TargetPlatform.iOS
                          ? (((widget.a is TopRopeAttempt ? (_ropeCompletedLocal ?? (widget.a as TopRopeAttempt).completed) : (_ropeCompletedLocal ?? (widget.a as LeadAttempt).completed)))
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.check_mark_circled)
                          : (((widget.a is TopRopeAttempt ? (_ropeCompletedLocal ?? (widget.a as TopRopeAttempt).completed) : (_ropeCompletedLocal ?? (widget.a as LeadAttempt).completed)))
                              ? Icons.check_circle
                              : Icons.check_circle_outline),
                      color: ((widget.a is TopRopeAttempt ? (_ropeCompletedLocal ?? (widget.a as TopRopeAttempt).completed) : (_ropeCompletedLocal ?? (widget.a as LeadAttempt).completed)))
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
              ],
            ),
          if (widget.a is BoulderingAttempt || widget.a is TopRopeAttempt || widget.a is LeadAttempt) const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Left-aligned difficulty + attempt pill using Wrap so the chip wraps under the title aligned to left.
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        child: Text(() {
                          if (widget.a is BoulderingAttempt) return title;
                          if (widget.a is TopRopeAttempt) return (widget.a as TopRopeAttempt).grade.value;
                          if (widget.a is LeadAttempt) return (widget.a as LeadAttempt).grade.value;
                          return title;
                        }()),
                      ),
                    ),
                    GestureDetector(
                  onTapDown: (TapDownDetails d) {
                    if (defaultTargetPlatform == TargetPlatform.iOS) return;
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    bool inc = true;
                    if (widget.a is BoulderingAttempt) {
                      final BoulderingAttempt b = widget.a as BoulderingAttempt;
                      final double localX = d.localPosition.dx;
                      inc = localX > (_attemptPillWidth / 2);
                      final int next = (b.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                      vm.updateBoulderAttemptNumber(b.id, next);
                    } else if (widget.a is TopRopeAttempt) {
                      final TopRopeAttempt t = widget.a as TopRopeAttempt;
                      final double localX = d.localPosition.dx;
                      inc = localX > (_attemptPillWidth / 2);
                      final int next = (t.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                      vm.updateTopRopeAttemptNumber(t.id, next);
                    } else if (widget.a is LeadAttempt) {
                      final LeadAttempt l = widget.a as LeadAttempt;
                      final double localX = d.localPosition.dx;
                      inc = localX > (_attemptPillWidth / 2);
                      final int next = (l.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                      vm.updateLeadAttemptNumber(l.id, next);
                    }
                    // Play fill animation for tap
                    setState(() {
                      _attemptDragDir = inc ? 1 : -1;
                      _attemptDragProgress = 1.0;
                    });
                    Future<void>.delayed(const Duration(milliseconds: 150), () {
                      if (!mounted) return;
                      setState(() {
                        _attemptDragProgress = 0.0;
                        _attemptDragDir = 0;
                      });
                    });
                  },
                  onHorizontalDragStart: (DragStartDetails d) {
                    if (defaultTargetPlatform == TargetPlatform.iOS) return;
                    _attemptDragStartX = d.globalPosition.dx;
                    setState(() {
                      _attemptDragProgress = 0;
                      _attemptDragDir = 0;
                    });
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails d) {
                    if (defaultTargetPlatform == TargetPlatform.iOS || _attemptDragStartX == null) return;
                    final double dx = d.globalPosition.dx - _attemptDragStartX!;
                    const double threshold = 80; // px for full fill
                    final int dir = dx == 0 ? 0 : (dx > 0 ? 1 : -1);
                    final double prog = (dx.abs() / threshold).clamp(0.0, 1.0);
                    setState(() {
                      _attemptDragDir = dir;
                      _attemptDragProgress = prog;
                    });
                  },
                  onHorizontalDragEnd: (DragEndDetails d) {
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    bool apply = _attemptDragProgress > 0.5 || d.velocity.pixelsPerSecond.dx.abs() > 400;
                    if (apply) {
                      final bool inc = _attemptDragDir >= 0 && d.velocity.pixelsPerSecond.dx >= 0;
                      if (widget.a is BoulderingAttempt) {
                        final BoulderingAttempt b = widget.a as BoulderingAttempt;
                        final int next = (b.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                        vm.updateBoulderAttemptNumber(b.id, next);
                      } else if (widget.a is TopRopeAttempt) {
                        final TopRopeAttempt t = widget.a as TopRopeAttempt;
                        final int next = (t.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                        vm.updateTopRopeAttemptNumber(t.id, next);
                      } else if (widget.a is LeadAttempt) {
                        final LeadAttempt l = widget.a as LeadAttempt;
                        final int next = (l.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                        vm.updateLeadAttemptNumber(l.id, next);
                      }
                    }
                    setState(() {
                      _attemptDragStartX = null;
                      _attemptDragProgress = 0;
                      _attemptDragDir = 0;
                    });
                  },
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : 120;
                      _attemptPillWidth = width;
                      final Color overlay = _attemptDragDir == 0
                          ? Colors.transparent
                          : (_attemptDragDir > 0
                              ? Colors.green.withValues(alpha: 0.25)
                              : Colors.red.withValues(alpha: 0.25));
                      final double fillWidth = width * _attemptDragProgress;
                      final bool showHint = defaultTargetPlatform != TargetPlatform.iOS;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (showHint)
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: _hintOpacity,
                                      child: Icon(Icons.chevron_left, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.36)),
                                    ),
                                  Text('Attempt ${() {
                                      if (widget.a is BoulderingAttempt) return (widget.a as BoulderingAttempt).attemptNo.toString();
                                      if (widget.a is TopRopeAttempt) return (widget.a as TopRopeAttempt).attemptNo.toString();
                                      if (widget.a is LeadAttempt) return (widget.a as LeadAttempt).attemptNo.toString();
                                      return '1';
                                    }()}'),
                                  if (showHint)
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: _hintOpacity,
                                      child: Icon(Icons.chevron_right, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.36)),
                ),
                if (widget.a is TopRopeAttempt || widget.a is LeadAttempt) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  Text('${(widget.a is TopRopeAttempt ? (widget.a as TopRopeAttempt).heightMeters : (widget.a as LeadAttempt).heightMeters).toStringAsFixed(1)} m',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
                                ],
                              ),
                            ),
                            if (_attemptDragDir != 0)
                              Positioned(
                                left: _attemptDragDir > 0 ? 0 : null,
                                right: _attemptDragDir < 0 ? 0 : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 80),
                                  curve: Curves.easeOut,
                                  width: fillWidth,
                                  height: 24,
                                  color: overlay,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (widget.a is TopRopeAttempt)
                _HeightToggleButton(attempt: widget.a as TopRopeAttempt, visible: showHeight, onToggle: () => setState(() => _showHeight = !_showHeight)),
              if (widget.a is LeadAttempt)
                _LeadHeightToggleButton(attempt: widget.a as LeadAttempt, visible: showHeight, onToggle: () => setState(() => _showHeight = !_showHeight)),
              if (widget.a is BoulderingAttempt || widget.a is TopRopeAttempt || widget.a is LeadAttempt)
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    AdaptiveIconButton(
                      onPressed: () => setState(() => _showNotes = !_showNotes),
                      icon: Icon(
                        defaultTargetPlatform == TargetPlatform.iOS
                            ? (_showNotes ? CupertinoIcons.doc_text : CupertinoIcons.text_alignleft)
                            : (_showNotes ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined),
                        color: _showNotes ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    if (hasNotes && !_showNotes)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if ((widget.a is TopRopeAttempt || widget.a is LeadAttempt) && showHeight) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            if (widget.a is TopRopeAttempt) _TopRopeControls(widget.a as TopRopeAttempt) else _LeadControls(widget.a as LeadAttempt),
          ],
          if (widget.a is BoulderingAttempt)
            _BoulderAttemptEditor(widget.a as BoulderingAttempt, showNotes: _showNotes),
          if ((widget.a is TopRopeAttempt || widget.a is LeadAttempt) && _showNotes)
            (widget.a is TopRopeAttempt) ? _RopedAttemptEditor(widget.a as TopRopeAttempt) : _LeadAttemptEditor(widget.a as LeadAttempt),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _BoulderAttemptEditor extends ConsumerStatefulWidget {
  const _BoulderAttemptEditor(this.attempt, {required this.showNotes});

  final BoulderingAttempt attempt;
  final bool showNotes;

  @override
  ConsumerState<_BoulderAttemptEditor> createState() => _BoulderAttemptEditorState();
}

class _BoulderAttemptEditorState extends ConsumerState<_BoulderAttemptEditor> {
  late final TextEditingController _notes = TextEditingController(text: widget.attempt.notes ?? '');

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Flashed moved to leading icon toggle on card header
        if (widget.showNotes)
          AdaptiveTextField(
          controller: _notes,
            labelText: 'Notes',
          minLines: 1,
          maxLines: 3,
          onChanged: (String v) => vm.updateBoulderAttemptNotes(widget.attempt.id, v.isEmpty ? null : v),
        ),
      ],
    );
  }
}

class _RopedAttemptEditor extends ConsumerStatefulWidget {
  const _RopedAttemptEditor(this.attempt);

  final TopRopeAttempt attempt;

  @override
  ConsumerState<_RopedAttemptEditor> createState() => _RopedAttemptEditorState();
}

class _RopedAttemptEditorState extends ConsumerState<_RopedAttemptEditor> {
  late final TextEditingController _notes = TextEditingController(text: widget.attempt.notes ?? '');

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdaptiveTextField(
          controller: _notes,
          labelText: 'Notes',
          minLines: 1,
          maxLines: 3,
          onChanged: (String v) => vm.updateTopRopeAttemptNotes(widget.attempt.id, v.isEmpty ? null : v),
        ),
      ],
    );
  }
}

class _LeadAttemptEditor extends ConsumerStatefulWidget {
  const _LeadAttemptEditor(this.attempt);

  final LeadAttempt attempt;

  @override
  ConsumerState<_LeadAttemptEditor> createState() => _LeadAttemptEditorState();
}

class _LeadAttemptEditorState extends ConsumerState<_LeadAttemptEditor> {
  late final TextEditingController _notes = TextEditingController(text: widget.attempt.notes ?? '');

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AdaptiveTextField(
          controller: _notes,
          labelText: 'Notes',
          minLines: 1,
          maxLines: 3,
          onChanged: (String v) => vm.updateLeadAttemptNotes(widget.attempt.id, v.isEmpty ? null : v),
        ),
      ],
    );
  }
}

class _TopRopeControls extends ConsumerStatefulWidget {
  const _TopRopeControls(this.attempt);

  final TopRopeAttempt attempt;

  @override
  ConsumerState<_TopRopeControls> createState() => _TopRopeControlsState();
}

class _TopRopeControlsState extends ConsumerState<_TopRopeControls> {
  @override
  Widget build(BuildContext context) {
    final double current = widget.attempt.heightMeters;
    final double maxH = current <= 20 ? 20 : ((current / 5).ceil() * 5).toDouble().clamp(20, 60);
    return _MountainHeightView(
      heightMeters: current,
      maxHeightMeters: maxH,
      onChanged: (double v) {
        final double rounded = double.parse(v.toStringAsFixed(1));
        ref.read(sessionLogProvider.notifier).updateTopRopeAttemptHeight(widget.attempt.id, rounded);
      },
    );
  }
}

class _LeadControls extends ConsumerStatefulWidget {
  const _LeadControls(this.attempt);

  final LeadAttempt attempt;

  @override
  ConsumerState<_LeadControls> createState() => _LeadControlsState();
}

class _LeadControlsState extends ConsumerState<_LeadControls> {
  @override
  Widget build(BuildContext context) {
    final double current = widget.attempt.heightMeters;
    final double maxH = current <= 20 ? 20 : ((current / 5).ceil() * 5).toDouble().clamp(20, 60);
    return _MountainHeightView(
      heightMeters: current,
      maxHeightMeters: maxH,
      onChanged: (double v) {
        final double rounded = double.parse(v.toStringAsFixed(1));
        ref.read(sessionLogProvider.notifier).updateLeadAttemptHeight(widget.attempt.id, rounded);
      },
    );
  }
}

class _HeightToggleButton extends StatelessWidget {
  const _HeightToggleButton({required this.attempt, required this.visible, required this.onToggle});

  final TopRopeAttempt attempt;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final bool hasHeight = attempt.heightMeters > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        AdaptiveIconButton(
          onPressed: onToggle,
          icon: Icon(
            defaultTargetPlatform == TargetPlatform.iOS
                ? (visible ? CupertinoIcons.rectangle_dock : CupertinoIcons.rectangle)
                : (visible ? Icons.stacked_bar_chart : Icons.stacked_bar_chart_outlined),
            color: visible ? Theme.of(context).colorScheme.primary : null,
          ),
          tooltip: 'Toggle height',
        ),
        if (hasHeight && !visible)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

class _LeadHeightToggleButton extends StatelessWidget {
  const _LeadHeightToggleButton({required this.attempt, required this.visible, required this.onToggle});

  final LeadAttempt attempt;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final bool hasHeight = attempt.heightMeters > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        AdaptiveIconButton(
          onPressed: onToggle,
          icon: Icon(
            defaultTargetPlatform == TargetPlatform.iOS
                ? (visible ? CupertinoIcons.rectangle_dock : CupertinoIcons.rectangle)
                : (visible ? Icons.stacked_bar_chart : Icons.stacked_bar_chart_outlined),
            color: visible ? Theme.of(context).colorScheme.primary : null,
          ),
          tooltip: 'Toggle height',
        ),
        if (hasHeight && !visible)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1),
              ),
            ),
          ),
      ],
    );
  }
}

// Removed legacy wall control class

class _EmptyAttempts extends StatelessWidget {
  const _EmptyAttempts();

  @override
  Widget build(BuildContext context) {
    return const Text('No attempts yet. Add one below.');
  }
}

class _StartOptions extends StatelessWidget {
  const _StartOptions({required this.onStart});

  final void Function(ClimbType type) onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Start a new session', style: AppTextStyles.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            AdaptiveFilledButton.icon(
              onPressed: () => onStart(ClimbType.bouldering),
              icon: const Icon(CupertinoIcons.circle_grid_3x3_fill),
              label: const Text('Bouldering'),
            ),
            AdaptiveFilledButton.icon(
              onPressed: () => onStart(ClimbType.topRope),
              icon: const Icon(CupertinoIcons.arrow_up_to_line),
              label: const Text('Top Rope'),
            ),
            AdaptiveFilledButton.icon(
              onPressed: () => onStart(ClimbType.lead),
              icon: const Icon(CupertinoIcons.bolt_fill),
              label: const Text('Lead'),
            ),
          ],
        ),
      ],
    );
  }
}


