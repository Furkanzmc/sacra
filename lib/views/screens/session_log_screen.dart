import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../models/session.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/v_grade_scrubber.dart';

class SessionLogScreen extends ConsumerWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionLogState state = ref.watch(sessionLogProvider);
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Log'),
        actions: <Widget>[
          if (state.activeSession == null)
            PopupMenuButton<ClimbType>(
              onSelected: (ClimbType t) => vm.startSession(t),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ClimbType>>[
                const PopupMenuItem<ClimbType>(
                  value: ClimbType.bouldering,
                  child: Text('Start Bouldering'),
                ),
                const PopupMenuItem<ClimbType>(
                  value: ClimbType.topRope,
                  child: Text('Start Top Rope'),
                ),
                const PopupMenuItem<ClimbType>(
                  value: ClimbType.lead,
                  child: Text('Start Lead'),
                ),
              ],
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start Session',
            )
          else
            IconButton(
              onPressed: vm.endSession,
              tooltip: 'End Session',
              icon: const Icon(Icons.stop),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.constrainedWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (state.activeSession == null)
                  const _EmptyPrompt()
                else
                  _ActiveSessionPane(session: state.activeSession!, vm: vm),
                const SizedBox(height: AppSpacing.lg),
                Text('Past Sessions', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _PastSessionsList(sessions: state.pastSessions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'No active session. Use the Play button in the app bar to start.',
      ),
    );
  }
}

class _ActiveSessionPane extends StatelessWidget {
  const _ActiveSessionPane({required this.session, required this.vm});

  final Session session;
  final SessionLogViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Active: ${session.climbType.name} • '
              '${TimeOfDay.fromDateTime(session.startTime).format(context)}',
              style: AppTextStyles.title,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _TypeAwareAttemptComposer(type: session.climbType, onAdd: vm.addAttempt),
        const SizedBox(height: AppSpacing.md),
        _AttemptsList(attempts: session.attempts),
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
            VGradeScrubber(
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
                    Checkbox(
                      value: _completed,
                      onChanged: (bool? v) => setState(() => _completed = v ?? false),
                    ),
                    Text('Completed'),
                  ],
                ),
                FilledButton.icon(
                  onPressed: _onAdd,
                  icon: const Icon(Icons.add),
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attempts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final ClimbAttempt a = attempts[index];
        return _AttemptTile(a);
      },
    );
  }
}

class _AttemptTile extends ConsumerWidget {
  const _AttemptTile(this.a);

  final ClimbAttempt a;

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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title),
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
            Checkbox(
              value: _sent,
              onChanged: (bool? v) {
                final bool next = v ?? false;
                setState(() => _sent = next);
                vm.updateBoulderAttemptSent(widget.attempt.id, next);
              },
            ),
            const Text('Sent'),
          ],
        ),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
          ),
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
    return const Text('No attempts yet. Add one above.');
  }
}

class _PastSessionsList extends StatelessWidget {
  const _PastSessionsList({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No past sessions'));
    }
    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final Session s = sessions[index];
        final String when = TimeOfDay.fromDateTime(s.startTime).format(context);
        final int count = s.attempts.length;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${s.climbType.name} • $when • $count attempts'),
        );
      },
    );
  }
}


