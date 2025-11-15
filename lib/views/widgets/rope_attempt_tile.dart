import 'package:flutter/material.dart';

import '../../models/session.dart';
import '../theme/app_theme.dart';

class RopeAttemptTile extends StatelessWidget {
  const RopeAttemptTile({super.key, required this.attempt});

  final ClimbAttempt attempt;

  @override
  Widget build(BuildContext context) {
    if (!(attempt is TopRopeAttempt) && !(attempt is LeadAttempt)) {
      return const SizedBox.shrink();
    }
    final bool isTopRope = attempt is TopRopeAttempt;
    final double height =
        isTopRope ? (attempt as TopRopeAttempt).heightMeters : (attempt as LeadAttempt).heightMeters;
    final String grade =
        isTopRope ? (attempt as TopRopeAttempt).grade.value : (attempt as LeadAttempt).grade.value;
    final bool completed =
        isTopRope ? (attempt as TopRopeAttempt).completed : (attempt as LeadAttempt).completed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$grade • ${height.toStringAsFixed(0)} m • ${completed ? 'Completed' : 'Attempt'}'),
    );
  }
}


