import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../models/session.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/v_grade_scrubber.dart';
import '../widgets/adaptive.dart';
import '../widgets/navigation_scope.dart';
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
        const SizedBox(height: AppSpacing.md),
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

class _AttemptCardState extends ConsumerState<_AttemptCard> {
  late bool _showNotes = widget.a is BoulderingAttempt && ((widget.a as BoulderingAttempt).notes ?? '').isNotEmpty;
  bool? _sentLocal;

  @override
  void initState() {
    super.initState();
    if (widget.a is BoulderingAttempt) {
      _sentLocal = (widget.a as BoulderingAttempt).sent;
    }
  }

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

    return AdaptiveCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.a is BoulderingAttempt)
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
              if (widget.a is BoulderingAttempt) ...<Widget>[
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('#${widget.number}'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title),
              if (widget.a is BoulderingAttempt) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails d) {
                    final bool inc = d.velocity.pixelsPerSecond.dx > 0;
                    final BoulderingAttempt b = widget.a as BoulderingAttempt;
                    final int next = (b.attemptNo + (inc ? 1 : -1)).clamp(1, 9999);
                    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                    vm.updateBoulderAttemptNumber(b.id, next);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Attempt ${(widget.a as BoulderingAttempt).attemptNo}'),
                  ),
                ),
              ],
              const Spacer(),
              if (widget.a is BoulderingAttempt)
                AdaptiveIconButton(
                  onPressed: () => setState(() => _showNotes = !_showNotes),
                  icon: Icon(
                    defaultTargetPlatform == TargetPlatform.iOS
                        ? (_showNotes ? CupertinoIcons.doc_text : CupertinoIcons.text_alignleft)
                        : (_showNotes ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined),
                    color: _showNotes ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
            ],
          ),
          if (widget.a is BoulderingAttempt)
            _BoulderAttemptEditor(widget.a as BoulderingAttempt, showNotes: _showNotes),
        ],
      ),
    );
  }
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
            labelText: 'Notes (optional)',
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


