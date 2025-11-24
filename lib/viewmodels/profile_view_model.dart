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
    required this.socialLinks,
  });

  final String? photoUrl;
  final String displayName;
  final String? location;
  final String? homeGym;
  final List<Buddy> buddies;
  final Set<ClimbType> interests;
  final Map<ClimbType, String> maxGrades;
  // key -> value, e.g. instagram -> @handle, website -> https://...
  final Map<String, String> socialLinks;

  ProfileState copyWith({
    String? photoUrl,
    String? displayName,
    String? location,
    String? homeGym,
    List<Buddy>? buddies,
    Set<ClimbType>? interests,
    Map<ClimbType, String>? maxGrades,
    Map<String, String>? socialLinks,
  }) {
    return ProfileState(
      photoUrl: photoUrl ?? this.photoUrl,
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      homeGym: homeGym ?? this.homeGym,
      buddies: buddies ?? this.buddies,
      interests: interests ?? this.interests,
      maxGrades: maxGrades ?? this.maxGrades,
      socialLinks: socialLinks ?? this.socialLinks,
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
      socialLinks: <String, String>{
        // examples left empty by default
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

  void updateSocialLink(String key, String? value) {
    final Map<String, String> next = Map<String, String>.from(state.socialLinks);
    if (value == null || value.trim().isEmpty) {
      next.remove(key);
    } else {
      next[key] = value.trim();
    }
    state = state.copyWith(socialLinks: next);
  }
}

final NotifierProvider<ProfileViewModel, ProfileState> profileProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);


