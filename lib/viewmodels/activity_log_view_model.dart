import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';

@immutable
class ActivityLogState {
  final List<ActivityEntry> entries;
  final bool isLoading;
  final String? errorMessage;

  const ActivityLogState({
    required this.entries,
    this.isLoading = false,
    this.errorMessage,
  });

  ActivityLogState copyWith({
    List<ActivityEntry>? entries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ActivityLogState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ActivityLogViewModel extends Notifier<ActivityLogState> {
  @override
  ActivityLogState build() {
    return const ActivityLogState(entries: <ActivityEntry>[]);
  }

  void addEntry(ActivityEntry entry) {
    final List<ActivityEntry> next = <ActivityEntry>[...state.entries, entry];
    state = state.copyWith(entries: next);
  }

  void removeEntry(String id) {
    final List<ActivityEntry> next =
        state.entries.where((ActivityEntry e) => e.id != id).toList();
    state = state.copyWith(entries: next);
  }
}

final NotifierProvider<ActivityLogViewModel, ActivityLogState>
    activityLogProvider =
    NotifierProvider<ActivityLogViewModel, ActivityLogState>(ActivityLogViewModel.new);

