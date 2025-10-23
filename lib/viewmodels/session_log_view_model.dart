import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../models/session.dart';

@immutable
class SessionLogState {
  const SessionLogState({
    required this.activeSession,
    required this.editingSession,
    required this.pastSessions,
  });

  final Session? activeSession;
  final Session? editingSession;
  final List<Session> pastSessions;

  SessionLogState copyWith({
    Session? activeSession,
    Session? editingSession,
    List<Session>? pastSessions,
  }) {
    return SessionLogState(
      activeSession: activeSession,
      editingSession: editingSession ?? this.editingSession,
      pastSessions: pastSessions ?? this.pastSessions,
    );
  }
}

class SessionLogViewModel extends Notifier<SessionLogState> {
  @override
  SessionLogState build() {
    return const SessionLogState(activeSession: null, editingSession: null, pastSessions: <Session>[]);
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
    final int existingIndex = state.pastSessions.indexWhere((Session s) => s.id == finished.id);
    if (existingIndex >= 0) {
      final List<Session> updated = <Session>[...state.pastSessions];
      updated[existingIndex] = finished;
    state = SessionLogState(activeSession: null, editingSession: state.editingSession, pastSessions: updated);
    } else {
      final List<Session> history = <Session>[finished, ...state.pastSessions];
      state = SessionLogState(activeSession: null, editingSession: state.editingSession, pastSessions: history);
    }
  }

  void editPastSession(String sessionId) {
    if (state.activeSession != null) {
      return;
    }
    final int idx = state.pastSessions.indexWhere((Session s) => s.id == sessionId);
    if (idx < 0) {
      return;
    }
    final Session toEdit = state.pastSessions[idx];
    state = state.copyWith(editingSession: toEdit);
  }

  void saveActiveSessionEdits() {
    final Session? current = state.editingSession;
    if (current == null) {
      return;
    }
    final int existingIndex = state.pastSessions.indexWhere((Session s) => s.id == current.id);
    if (existingIndex >= 0) {
      final List<Session> updated = <Session>[...state.pastSessions];
      updated[existingIndex] = current;
      state = SessionLogState(activeSession: null, editingSession: null, pastSessions: updated);
    } else {
      final List<Session> history = <Session>[current, ...state.pastSessions];
      state = SessionLogState(activeSession: null, editingSession: null, pastSessions: history);
    }
  }

  void clearEditingSession() {
    if (state.editingSession == null) {
      return;
    }
    state = state.copyWith(editingSession: null);
  }

  void addAttempt(ClimbAttempt attempt) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = <ClimbAttempt>[...current.attempts, attempt];
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next = <ClimbAttempt>[...current.attempts, attempt];
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateBoulderAttemptNumber(String attemptId, int attemptNumber) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(attemptNumber: attemptNumber);
        }
        return a;
      }).toList();
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(attemptNumber: attemptNumber);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateBoulderAttemptSent(String attemptId, bool sent) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(sent: sent);
        }
        return a;
      }).toList();
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(sent: sent);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateBoulderAttemptCompleted(String attemptId, bool completed) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(completed: completed);
        }
        return a;
      }).toList();
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(completed: completed);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateBoulderAttemptNotes(String attemptId, String? notes) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(notes: notes);
        }
        return a;
      }).toList();
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is BoulderingAttempt && a.id == attemptId) {
          return a.copyWith(notes: notes);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }
}

final NotifierProvider<SessionLogViewModel, SessionLogState> sessionLogProvider =
    NotifierProvider<SessionLogViewModel, SessionLogState>(SessionLogViewModel.new);

