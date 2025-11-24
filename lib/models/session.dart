import 'package:flutter/foundation.dart';

import 'activity.dart';

@immutable
sealed class ClimbAttempt {
  const ClimbAttempt({
    required this.id,
    required this.timestamp,
    this.routeName,
    this.notes,
  });

  final String id;
  final DateTime timestamp;
  final String? routeName;
  final String? notes;
}

class BoulderingAttempt extends ClimbAttempt {
  const BoulderingAttempt({
    required super.id,
    required super.timestamp,
    required this.grade,
    required this.sent,
    required this.completed,
    this.attemptNumber,
    super.routeName,
    super.notes,
  });

  final Grade grade;
  final bool sent;
  final bool? completed;
  final int? attemptNumber;

  int get attemptNo => attemptNumber ?? 1;
  bool get isCompleted => completed ?? false;

  BoulderingAttempt copyWith({
    Grade? grade,
    bool? sent,
    bool? completed,
    int? attemptNumber,
    String? notes,
  }) {
    return BoulderingAttempt(
      id: id,
      timestamp: timestamp,
      grade: grade ?? this.grade,
      sent: sent ?? this.sent,
      completed: completed ?? this.completed,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      routeName: routeName,
      notes: notes ?? this.notes,
    );
  }
}

class TopRopeAttempt extends ClimbAttempt {
  const TopRopeAttempt({
    required super.id,
    required super.timestamp,
    required this.grade,
    required this.heightMeters,
    required this.falls,
    required this.completed,
    this.sent,
    this.attemptNumber,
    super.routeName,
    super.notes,
  });

  final Grade grade;
  final double heightMeters;
  final int falls;
  final bool completed;
  final bool? sent;
  final int? attemptNumber;

  int get attemptNo => attemptNumber ?? 1;
  bool get isSent => sent ?? false;

  TopRopeAttempt copyWith({
    Grade? grade,
    double? heightMeters,
    int? falls,
    bool? completed,
    bool? sent,
    int? attemptNumber,
    String? notes,
  }) {
    return TopRopeAttempt(
      id: id,
      timestamp: timestamp,
      grade: grade ?? this.grade,
      heightMeters: heightMeters ?? this.heightMeters,
      falls: falls ?? this.falls,
      completed: completed ?? this.completed,
      sent: sent ?? this.sent,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      routeName: routeName,
      notes: notes ?? this.notes,
    );
  }
}

class LeadAttempt extends ClimbAttempt {
  const LeadAttempt({
    required super.id,
    required super.timestamp,
    required this.grade,
    required this.heightMeters,
    required this.falls,
    required this.completed,
    this.sent,
    this.attemptNumber,
    super.routeName,
    super.notes,
  });

  final Grade grade;
  final double heightMeters;
  final int falls;
  final bool completed;
  final bool? sent;
  final int? attemptNumber;

  int get attemptNo => attemptNumber ?? 1;
  bool get isSent => sent ?? false;

  LeadAttempt copyWith({
    Grade? grade,
    double? heightMeters,
    int? falls,
    bool? completed,
    bool? sent,
    int? attemptNumber,
    String? notes,
  }) {
    return LeadAttempt(
      id: id,
      timestamp: timestamp,
      grade: grade ?? this.grade,
      heightMeters: heightMeters ?? this.heightMeters,
      falls: falls ?? this.falls,
      completed: completed ?? this.completed,
      sent: sent ?? this.sent,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      routeName: routeName,
      notes: notes ?? this.notes,
    );
  }
}

@immutable
class Session {
  const Session({
    required this.id,
    required this.startTime,
    required this.climbType,
    required this.attempts,
    this.gymName,
    this.endTime,
    this.notes,
    this.rating,
  });

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final ClimbType climbType;
  final String? gymName;
  final List<ClimbAttempt> attempts;
  final String? notes;
  final int? rating; // 1-5 emoji rating

  bool get isActive => endTime == null;

  Session copyWith({
    DateTime? startTime,
    DateTime? endTime,
    ClimbType? climbType,
    String? gymName,
    List<ClimbAttempt>? attempts,
    String? notes,
    int? rating,
    bool clearRating = false,
  }) {
    return Session(
      id: id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      climbType: climbType ?? this.climbType,
      gymName: gymName ?? this.gymName,
      attempts: attempts ?? this.attempts,
      notes: notes ?? this.notes,
      rating: clearRating ? null : (rating ?? this.rating),
    );
  }
}

