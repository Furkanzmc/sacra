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
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionLogState state = ref.watch(sessionLogProvider);
    final Session? session = state.activeSession;
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);

    return AdaptiveScaffold(
      title: Text(
        session == null ? 'Active Session' : 'Active: ${session.climbType.name}',
        style: AppTextStyles.title,
      ),
      actions: session == null
          ? null
          : <Widget>[
              AdaptiveIconButton(
                onPressed: () {
                  vm.endSession();
                  Navigator.of(context).pop();
                },
                tooltip: 'End Session',
                icon: Icon(_adaptiveStopIcon()),
              ),
            ],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.constrainedWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: session == null
                ? _StartOptions(onStart: vm.startSession)
                : _ActiveBody(session: session),
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
        return _AttemptTile(a, displayNumber);
      },
    );
  }
}

class _AttemptTile extends ConsumerWidget {
  const _AttemptTile(this.a, this.number);

  final ClimbAttempt a;
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late final String title;
    if (a is BoulderingAttempt) {
      final BoulderingAttempt b = a as BoulderingAttempt;
      title = '${b.grade.value} • ${b.sent ? 'Sent' : 'Project'}';
    } else if (a is TopRopeAttempt) {
      final TopRopeAttempt t = a as TopRopeAttempt;
      title = '${t.grade.value} • ${t.heightMeters} m • ${t.completed ? 'Completed' : 'Attempt'}';
    } else if (a is LeadAttempt) {
      final LeadAttempt l = a as LeadAttempt;
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('#$number'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title),
            ],
          ),
          if (a is BoulderingAttempt) _BoulderAttemptEditor(a as BoulderingAttempt),
        ],
      ),
    );
  }
}

class _BoulderAttemptEditor extends ConsumerStatefulWidget {
  const _BoulderAttemptEditor(this.attempt);

  final BoulderingAttempt attempt;

  @override
  ConsumerState<_BoulderAttemptEditor> createState() => _BoulderAttemptEditorState();
}

class _BoulderAttemptEditorState extends ConsumerState<_BoulderAttemptEditor> {
  late bool _sent = widget.attempt.sent;
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AdaptiveSwitch(
              value: _sent,
              onChanged: (bool v) {
                setState(() => _sent = v);
                vm.updateBoulderAttemptSent(widget.attempt.id, v);
              },
            ),
            const Text('Sent'),
          ],
        ),
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


