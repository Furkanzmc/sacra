import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';

@immutable
class Buddy {
  const Buddy({required this.id, required this.name, this.avatarUrl});
  final String id;
  final String name;
  final String? avatarUrl;
}

@immutable
class ProfileState {
  const ProfileState({
    required this.photoUrl,
    required this.displayName,
    required this.location,
    required this.homeGym,
    required this.buddies,
    required this.interests,
    required this.maxGrades,
  });

  final String? photoUrl;
  final String displayName;
  final String? location;
  final String? homeGym;
  final List<Buddy> buddies;
  final Set<ClimbType> interests;
  final Map<ClimbType, String> maxGrades;

  ProfileState copyWith({
    String? photoUrl,
    String? displayName,
    String? location,
    String? homeGym,
    List<Buddy>? buddies,
    Set<ClimbType>? interests,
    Map<ClimbType, String>? maxGrades,
  }) {
    return ProfileState(
      photoUrl: photoUrl ?? this.photoUrl,
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      homeGym: homeGym ?? this.homeGym,
      buddies: buddies ?? this.buddies,
      interests: interests ?? this.interests,
      maxGrades: maxGrades ?? this.maxGrades,
    );
  }
}

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Seed with simple example data; will be replaced with persistence later.
    return const ProfileState(
      photoUrl: null,
      displayName: 'Your Name',
      location: 'San Francisco, CA',
      homeGym: 'Mission Cliffs',
      buddies: <Buddy>[
        Buddy(id: 'b1', name: 'Ava'),
        Buddy(id: 'b2', name: 'Ben'),
        Buddy(id: 'b3', name: 'Kai'),
      ],
      interests: <ClimbType>{ClimbType.bouldering, ClimbType.topRope, ClimbType.lead},
      maxGrades: <ClimbType, String>{
        ClimbType.bouldering: 'V4',
        ClimbType.topRope: '5.11a',
        ClimbType.lead: '5.10b',
      },
    );
  }

  void updateName(String name) {
    state = state.copyWith(displayName: name);
  }

  void updateLocation(String? location) {
    state = state.copyWith(location: (location?.isEmpty ?? true) ? null : location);
  }

  void updateHomeGym(String? gym) {
    state = state.copyWith(homeGym: (gym?.isEmpty ?? true) ? null : gym);
  }

  void updatePhotoUrl(String? url) {
    state = state.copyWith(photoUrl: url);
  }

  void addBuddy(Buddy buddy) {
    final List<Buddy> next = <Buddy>[...state.buddies, buddy];
    state = state.copyWith(buddies: next);
  }

  void removeBuddy(String buddyId) {
    final List<Buddy> next = state.buddies.where((Buddy b) => b.id != buddyId).toList();
    state = state.copyWith(buddies: next);
  }

  void toggleInterest(ClimbType type) {
    final Set<ClimbType> next = Set<ClimbType>.from(state.interests);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    state = state.copyWith(interests: next);
  }

  void setMaxGrade(ClimbType type, String grade) {
    final Map<ClimbType, String> next = Map<ClimbType, String>.from(state.maxGrades);
    next[type] = grade;
    state = state.copyWith(maxGrades: next);
  }
}

final NotifierProvider<ProfileViewModel, ProfileState> profileProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);


