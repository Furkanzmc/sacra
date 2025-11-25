import 'package:flutter/foundation.dart';

enum ClimbType { bouldering, topRope, lead }

enum GradeSystem { vScale, yds, font, gymColor }

@immutable
class Grade {
  final GradeSystem system;
  final String value;

  const Grade({required this.system, required this.value});
}

@immutable
class ActivityEntry {
  final String id;
  final DateTime timestamp;
  final ClimbType climbType;
  final Grade grade;
  final int attempts;
  final bool completed;
  final String? notes;

  const ActivityEntry({
    required this.id,
    required this.timestamp,
    required this.climbType,
    required this.grade,
    required this.attempts,
    required this.completed,
    this.notes,
  });

  ActivityEntry copyWith({
    String? id,
    DateTime? timestamp,
    ClimbType? climbType,
    Grade? grade,
    int? attempts,
    bool? completed,
    String? notes,
  }) {
    return ActivityEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      climbType: climbType ?? this.climbType,
      grade: grade ?? this.grade,
      attempts: attempts ?? this.attempts,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }
}

@immutable
class ActivityComment {
  final String id;
  final String user;
  final String text;
  final DateTime timestamp;

  const ActivityComment({
    required this.id,
    required this.user,
    required this.text,
    required this.timestamp,
  });
}

