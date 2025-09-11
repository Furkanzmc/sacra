import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../models/session.dart';

@immutable
class SessionLogState {
  const SessionLogState({
    required this.activeSession,
    required this.pastSessions,
  });

  final Session? activeSession;
  final List<Session> pastSessions;

  SessionLogState copyWith({
    Session? activeSession,
    List<Session>? pastSessions,
  }) {
    return SessionLogState(
      activeSession: activeSession,
      pastSessions: pastSessions ?? this.pastSessions,
    );
  }
}

class SessionLogViewModel extends Notifier<SessionLogState> {
  @override
  SessionLogState build() {
    return const SessionLogState(activeSession: null, pastSessions: <Session>[]);
  }

  void startSession(ClimbType type, {String? gymName}) {
    if (state.activeSession != null) {
      return;
    }
    state = state.copyWith(
      activeSession: Session(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        climbType: type,
        gymName: gymName,
        attempts: <ClimbAttempt>[],
      ),
    );
  }

  void endSession() {
    final Session? current = state.activeSession;
    if (current == null) {
      return;
    }
    final Session finished = current.copyWith(endTime: DateTime.now());
    final List<Session> history = <Session>[finished, ...state.pastSessions];
    state = SessionLogState(activeSession: null, pastSessions: history);
  }

  void addAttempt(ClimbAttempt attempt) {
    final Session? current = state.activeSession;
    if (current == null) {
      return;
    }
    final List<ClimbAttempt> next = <ClimbAttempt>[...current.attempts, attempt];
    state = state.copyWith(activeSession: current.copyWith(attempts: next));
  }

  void updateBoulderAttemptSent(String attemptId, bool sent) {
    final Session? current = state.activeSession;
    if (current == null) {
      return;
    }
    final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
      if (a is BoulderingAttempt && a.id == attemptId) {
        return a.copyWith(sent: sent);
      }
      return a;
    }).toList();
    state = state.copyWith(activeSession: current.copyWith(attempts: next));
  }

  void updateBoulderAttemptNotes(String attemptId, String? notes) {
    final Session? current = state.activeSession;
    if (current == null) {
      return;
    }
    final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
      if (a is BoulderingAttempt && a.id == attemptId) {
        return a.copyWith(notes: notes);
      }
      return a;
    }).toList();
    state = state.copyWith(activeSession: current.copyWith(attempts: next));
  }
}

final NotifierProvider<SessionLogViewModel, SessionLogState> sessionLogProvider =
    NotifierProvider<SessionLogViewModel, SessionLogState>(SessionLogViewModel.new);

