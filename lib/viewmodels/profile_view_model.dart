import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final String? photoUrl;
  final String displayName;
  final String? location;
  final String? homeGym;
  final List<Buddy> buddies;

  ProfileState copyWith({
    String? photoUrl,
    String? displayName,
    String? location,
    String? homeGym,
    List<Buddy>? buddies,
  }) {
    return ProfileState(
      photoUrl: photoUrl ?? this.photoUrl,
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      homeGym: homeGym ?? this.homeGym,
      buddies: buddies ?? this.buddies,
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
}

final NotifierProvider<ProfileViewModel, ProfileState> profileProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);


