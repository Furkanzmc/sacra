import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/session.dart';
import '../theme/app_theme.dart';
import 'v_grade_scrubber.dart';

class RopeAttemptComposer extends StatefulWidget {
  const RopeAttemptComposer({
    super.key,
    required this.ropeType,
    required this.onAdd,
  });

  final ClimbType ropeType; // ClimbType.topRope or ClimbType.lead
  final void Function(ClimbAttempt attempt) onAdd;

  @override
  State<RopeAttemptComposer> createState() => _RopeAttemptComposerState();
}

class _RopeAttemptComposerState extends State<RopeAttemptComposer> {
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
    final String heading =
        widget.ropeType == ClimbType.topRope ? 'Top rope' : 'Lead';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Add Attempt ($heading)'),
          const SizedBox(height: AppSpacing.sm),
          // Gesture-based YDS picker with quick buttons
          YdsGradePopupScrubber(
            trailing: SizedBox(
              width: 120,
              child: TextField(
                controller: _heightCtrl,
                decoration: const InputDecoration(labelText: 'Height (m)'),
                keyboardType: TextInputType.number,
              ),
            ),
            onPicked: (Grade g) {
              _gradeCtrl.text = g.value;
              _addAttempt();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Checkbox(
                value: _completed,
                onChanged: (bool? v) =>
                    setState(() => _completed = v ?? false),
              ),
              const Text('Completed'),
            ],
          ),
        ],
      ),
    );
  }

  void _addAttempt() {
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime now = DateTime.now();
    final Grade grade = Grade(
      system: GradeSystem.yds,
      value: _gradeCtrl.text.isEmpty ? '5.10a' : _gradeCtrl.text,
    );
    final double height = double.tryParse(_heightCtrl.text) ?? 0;

    final ClimbAttempt attempt = widget.ropeType == ClimbType.topRope
        ? TopRopeAttempt(
            id: id,
            timestamp: now,
            grade: grade,
            heightMeters: height,
            falls: 0,
            completed: _completed,
          )
        : LeadAttempt(
            id: id,
            timestamp: now,
            grade: grade,
            heightMeters: height,
            falls: 0,
            completed: _completed,
          );

    widget.onAdd(attempt);
    _completed = false;
    _heightCtrl.clear();
    _gradeCtrl.clear();
    setState(() {});
  }
}


