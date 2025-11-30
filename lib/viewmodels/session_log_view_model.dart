import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../models/session.dart';
import 'profile_view_model.dart';

@immutable
class SessionLogState {
  const SessionLogState({
    required this.activeSession,
    required this.editingSession,
    required this.pastSessions,
    required this.likesBySession,
    required this.commentsBySession,
    required this.commentLikesById,
  });

  final Session? activeSession;
  final Session? editingSession;
  final List<Session> pastSessions;
  final Map<String, Set<String>> likesBySession;
  final Map<String, List<ActivityComment>> commentsBySession;
  // commentId -> set of user display names who liked that comment
  final Map<String, Set<String>> commentLikesById;

  SessionLogState copyWith({
    Session? activeSession,
    Session? editingSession,
    List<Session>? pastSessions,
    Map<String, Set<String>>? likesBySession,
    Map<String, List<ActivityComment>>? commentsBySession,
    Map<String, Set<String>>? commentLikesById,
  }) {
    return SessionLogState(
      activeSession: activeSession,
      editingSession: editingSession ?? this.editingSession,
      pastSessions: pastSessions ?? this.pastSessions,
      likesBySession: likesBySession ?? this.likesBySession,
      commentsBySession: commentsBySession ?? this.commentsBySession,
      commentLikesById: commentLikesById ?? this.commentLikesById,
    );
  }
}

class SessionLogViewModel extends Notifier<SessionLogState> {
  @override
  SessionLogState build() {
    return SessionLogState(
      activeSession: null,
      editingSession: null,
      pastSessions: <Session>[],
      likesBySession: <String, Set<String>>{},
      commentsBySession: <String, List<ActivityComment>>{},
      commentLikesById: <String, Set<String>>{},
    );
  }

  void startSession(ClimbType type, {String? gymName}) {
    if (state.activeSession != null) {
      return;
    }
    // Default gym from profile if none provided
    final String? defaultGym = gymName ?? ref.read(profileProvider).homeGym;
    state = state.copyWith(
      activeSession: Session(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        climbType: type,
        gymName: defaultGym,
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
    state = SessionLogState(
        activeSession: null,
        editingSession: state.editingSession,
        pastSessions: updated,
        likesBySession: state.likesBySession,
        commentsBySession: state.commentsBySession,
        commentLikesById: state.commentLikesById);
    } else {
      final List<Session> history = <Session>[finished, ...state.pastSessions];
      state = SessionLogState(
          activeSession: null,
          editingSession: state.editingSession,
          pastSessions: history,
          likesBySession: state.likesBySession,
          commentsBySession: state.commentsBySession,
          commentLikesById: state.commentLikesById);
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
      state = SessionLogState(
          activeSession: null,
          editingSession: null,
          pastSessions: updated,
          likesBySession: state.likesBySession,
          commentsBySession: state.commentsBySession,
          commentLikesById: state.commentLikesById);
    } else {
      final List<Session> history = <Session>[current, ...state.pastSessions];
      state = SessionLogState(
          activeSession: null,
          editingSession: null,
          pastSessions: history,
          likesBySession: state.likesBySession,
          commentsBySession: state.commentsBySession,
          commentLikesById: state.commentLikesById);
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

  void deleteAttempt(String attemptId) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next =
          current.attempts.where((ClimbAttempt a) => a.id != attemptId).toList();
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next =
          current.attempts.where((ClimbAttempt a) => a.id != attemptId).toList();
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

  void updateTopRopeAttemptCompleted(String attemptId, bool completed) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is TopRopeAttempt && a.id == attemptId) {
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
        if (a is TopRopeAttempt && a.id == attemptId) {
          return a.copyWith(completed: completed);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateTopRopeAttemptNotes(String attemptId, String? notes) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is TopRopeAttempt && a.id == attemptId) {
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
        if (a is TopRopeAttempt && a.id == attemptId) {
          return a.copyWith(notes: notes);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateTopRopeAttemptHeight(String attemptId, double heightMeters) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is TopRopeAttempt && a.id == attemptId) {
          return a.copyWith(heightMeters: heightMeters);
        }
        return a;
      }).toList();
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is TopRopeAttempt && a.id == attemptId) {
          return a.copyWith(heightMeters: heightMeters);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateTopRopeAttemptNumber(String attemptId, int attemptNumber) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is TopRopeAttempt && a.id == attemptId) {
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
        if (a is TopRopeAttempt && a.id == attemptId) {
          return a.copyWith(attemptNumber: attemptNumber);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateTopRopeAttemptSent(String attemptId, bool sent) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is TopRopeAttempt && a.id == attemptId) {
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
        if (a is TopRopeAttempt && a.id == attemptId) {
          return a.copyWith(sent: sent);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateLeadAttemptCompleted(String attemptId, bool completed) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is LeadAttempt && a.id == attemptId) {
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
        if (a is LeadAttempt && a.id == attemptId) {
          return a.copyWith(completed: completed);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateLeadAttemptNotes(String attemptId, String? notes) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is LeadAttempt && a.id == attemptId) {
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
        if (a is LeadAttempt && a.id == attemptId) {
          return a.copyWith(notes: notes);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateLeadAttemptHeight(String attemptId, double heightMeters) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is LeadAttempt && a.id == attemptId) {
          return a.copyWith(heightMeters: heightMeters);
        }
        return a;
      }).toList();
      state = state.copyWith(activeSession: current.copyWith(attempts: next));
      return;
    }
    if (state.editingSession != null) {
      final Session current = state.editingSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is LeadAttempt && a.id == attemptId) {
          return a.copyWith(heightMeters: heightMeters);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateLeadAttemptNumber(String attemptId, int attemptNumber) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is LeadAttempt && a.id == attemptId) {
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
        if (a is LeadAttempt && a.id == attemptId) {
          return a.copyWith(attemptNumber: attemptNumber);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateLeadAttemptSent(String attemptId, bool sent) {
    if (state.activeSession != null) {
      final Session current = state.activeSession!;
      final List<ClimbAttempt> next = current.attempts.map((ClimbAttempt a) {
        if (a is LeadAttempt && a.id == attemptId) {
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
        if (a is LeadAttempt && a.id == attemptId) {
          return a.copyWith(sent: sent);
        }
        return a;
      }).toList();
      state = state.copyWith(editingSession: current.copyWith(attempts: next));
    }
  }

  void updateSessionNotes(String? notes) {
    if (state.activeSession != null) {
      final Session s = state.activeSession!;
      state = state.copyWith(activeSession: s.copyWith(notes: notes));
      return;
    }
    if (state.editingSession != null) {
      final Session s = state.editingSession!;
      state = state.copyWith(editingSession: s.copyWith(notes: notes));
    }
  }

  void updateSessionGymName(String? gymName) {
    if (state.activeSession != null) {
      final Session s = state.activeSession!;
      state = state.copyWith(activeSession: s.copyWith(gymName: gymName));
      return;
    }
    if (state.editingSession != null) {
      final Session s = state.editingSession!;
      state = state.copyWith(editingSession: s.copyWith(gymName: gymName));
    }
  }

  void updateSessionRating(int? rating) {
    if (state.activeSession != null) {
      final Session s = state.activeSession!;
      state = state.copyWith(activeSession: s.copyWith(rating: rating, clearRating: rating == null));
      return;
    }
    if (state.editingSession != null) {
      final Session s = state.editingSession!;
      state = state.copyWith(editingSession: s.copyWith(rating: rating, clearRating: rating == null));
    }
  }

  // --- Social (prototype) ---
  void toggleLike(String sessionId, {required String user}) {
    final Map<String, Set<String>> map = Map<String, Set<String>>.from(state.likesBySession);
    final Set<String> set = map.putIfAbsent(sessionId, () => <String>{});
    if (set.contains(user)) {
      set.remove(user);
    } else {
      set.add(user);
    }
    map[sessionId] = set;
    state = state.copyWith(likesBySession: map);
  }

  void addComment(String sessionId, ActivityComment c) {
    final Map<String, List<ActivityComment>> map =
        Map<String, List<ActivityComment>>.from(state.commentsBySession);
    final List<ActivityComment> list = List<ActivityComment>.from(map[sessionId] ?? <ActivityComment>[]);
    list.add(c);
    map[sessionId] = list;
    state = state.copyWith(commentsBySession: map);
  }

  void editComment(String sessionId, String commentId, String newText) {
    final Map<String, List<ActivityComment>> map =
        Map<String, List<ActivityComment>>.from(state.commentsBySession);
    final List<ActivityComment> list = List<ActivityComment>.from(map[sessionId] ?? <ActivityComment>[]);
    final int idx = list.indexWhere((ActivityComment c) => c.id == commentId);
    if (idx < 0) return;
    final ActivityComment old = list[idx];
    list[idx] = ActivityComment(id: old.id, user: old.user, text: newText, timestamp: old.timestamp);
    map[sessionId] = list;
    state = state.copyWith(commentsBySession: map);
  }

  void deleteComment(String sessionId, String commentId) {
    final Map<String, List<ActivityComment>> map =
        Map<String, List<ActivityComment>>.from(state.commentsBySession);
    final List<ActivityComment> list = List<ActivityComment>.from(map[sessionId] ?? <ActivityComment>[]);
    map[sessionId] = list.where((ActivityComment c) => c.id != commentId).toList();
    // also clear likes for that comment
    final Map<String, Set<String>> likes = Map<String, Set<String>>.from(state.commentLikesById);
    likes.remove(commentId);
    state = state.copyWith(commentsBySession: map, commentLikesById: likes);
  }

  void toggleCommentLike(String commentId, {required String user}) {
    final Map<String, Set<String>> likes = Map<String, Set<String>>.from(state.commentLikesById);
    final Set<String> set = likes.putIfAbsent(commentId, () => <String>{});
    if (set.contains(user)) {
      set.remove(user);
    } else {
      set.add(user);
    }
    likes[commentId] = set;
    state = state.copyWith(commentLikesById: likes);
  }
}

final NotifierProvider<SessionLogViewModel, SessionLogState> sessionLogProvider =
    NotifierProvider<SessionLogViewModel, SessionLogState>(SessionLogViewModel.new);

