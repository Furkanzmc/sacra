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

    return AdaptiveScaffold(
      title: Text(
        effectiveSession == null ? 'Active Session' : 'Active: ${effectiveSession.climbType.name}',
        style: AppTextStyles.title,
      ),
      actions: (session != null)
          ? null // viewing/editing a past session; no end button
          : (effectiveSession == null
              ? null
              : <Widget>[
        AdaptiveIconButton(
          onPressed: () {
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
          labelText: 'Session notes (optional)',
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
          Text('Add Attempt (${widget.type.name})'),
          const SizedBox(height: AppSpacing.sm),
          if (widget.type == ClimbType.bouldering)
            VGradePopupScrubber(
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
            grade: grade,
            heightMeters: height,
            falls: 0,
            completed: _completed,
          ),
        );
        break;
      case ClimbType.lead:
        final double height = double.tryParse(_heightCtrl.text) ?? 0;
        widget.onAdd(
          LeadAttempt(
            id: id,
            timestamp: now,
            grade: grade,
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
  late bool _showNotes = widget.a is BoulderingAttempt && ((widget.a as BoulderingAttempt).notes ?? '').isNotEmpty;
  bool? _sentLocal;
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
    } else {
      _sentLocal = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    late final String title;
    if (widget.a is BoulderingAttempt) {
      final BoulderingAttempt b = widget.a as BoulderingAttempt;
      final bool flashed = _sentLocal ?? b.sent;
      title = '${b.grade.value} • ${flashed ? 'Flashed' : 'Project'}';
    } else if (widget.a is TopRopeAttempt) {
      final TopRopeAttempt t = widget.a as TopRopeAttempt;
      title = '${t.grade.value} • ${t.heightMeters} m • ${t.completed ? 'Completed' : 'Attempt'}';
    } else if (widget.a is LeadAttempt) {
      final LeadAttempt l = widget.a as LeadAttempt;
      title = '${l.grade.value} • ${l.heightMeters} m • ${l.completed ? 'Completed' : 'Attempt'}';
    } else {
      title = 'Attempt';
    }

    final bool hasNotes = widget.a is BoulderingAttempt && (((widget.a as BoulderingAttempt).notes) ?? '').isNotEmpty;

    return AdaptiveCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.a is BoulderingAttempt)
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
                // Flashed
                AdaptiveIconButton(
                  onPressed: () {
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    final BoulderingAttempt b = widget.a as BoulderingAttempt;
                    final bool next = !(_sentLocal ?? b.sent);
                    setState(() => _sentLocal = next);
                    vm.updateBoulderAttemptSent(b.id, next);
                  },
                  icon: Icon(
                    defaultTargetPlatform == TargetPlatform.iOS
                        ? ((_sentLocal ?? (widget.a as BoulderingAttempt).sent) ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt)
                        : ((_sentLocal ?? (widget.a as BoulderingAttempt).sent) ? Icons.bolt : Icons.bolt_outlined),
                    color: (_sentLocal ?? (widget.a as BoulderingAttempt).sent) ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                // Completed
                AdaptiveIconButton(
                  onPressed: () {
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    final BoulderingAttempt b = widget.a as BoulderingAttempt;
                    vm.updateBoulderAttemptCompleted(b.id, !(b.isCompleted));
                  },
                  icon: Icon(
                    defaultTargetPlatform == TargetPlatform.iOS
                        ? (((widget.a as BoulderingAttempt).isCompleted) ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.check_mark_circled)
                        : (((widget.a as BoulderingAttempt).isCompleted) ? Icons.check_circle : Icons.check_circle_outline),
                    color: ((widget.a as BoulderingAttempt).isCompleted) ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          if (widget.a is BoulderingAttempt) const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Title first on second row
              Text(title),
              if (widget.a is BoulderingAttempt) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTapDown: (TapDownDetails d) {
                    if (defaultTargetPlatform == TargetPlatform.iOS) return;
                    final BoulderingAttempt b = widget.a as BoulderingAttempt;
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    final double localX = d.localPosition.dx;
                    final bool inc = localX > (_attemptPillWidth / 2);
                    final int next = (b.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                    vm.updateBoulderAttemptNumber(b.id, next);
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
                    final BoulderingAttempt b = widget.a as BoulderingAttempt;
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    bool apply = _attemptDragProgress > 0.5 || d.velocity.pixelsPerSecond.dx.abs() > 400;
                    if (apply) {
                      final bool inc = _attemptDragDir >= 0 && d.velocity.pixelsPerSecond.dx >= 0;
                      final int next = (b.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                      vm.updateBoulderAttemptNumber(b.id, next);
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
                                  Text('Attempt ${(widget.a as BoulderingAttempt).attemptNo}'),
                                  if (showHint)
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: _hintOpacity,
                                      child: Icon(Icons.chevron_right, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.36)),
                                    ),
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
              const Spacer(),
              if (widget.a is BoulderingAttempt)
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
          if (widget.a is BoulderingAttempt)
            _BoulderAttemptEditor(widget.a as BoulderingAttempt, showNotes: _showNotes),
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


