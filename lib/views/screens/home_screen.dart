import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/adaptive.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../theme/app_theme.dart';
import '../../models/session.dart';
import 'all_sessions_screen.dart';
import 'profile_screen.dart';
import '../widgets/activity_list.dart';
import 'active_session_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionLogProvider); // Observe changes to refresh Home
    return AdaptiveScaffold(
      title: const Text('Home'),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<Widget>(builder: (_) => const ProfileScreen()));
          },
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Feed: user's and buddies' activities (currently using user's sessions; buddies to be wired later)
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  final List<Session> sessions = <Session>[
                    ...ref.watch(sessionLogProvider).pastSessions
                  ]..sort((Session a, Session b) => (b.endTime ?? b.startTime).compareTo(a.endTime ?? a.startTime));
                  final List<ActivityListItem> items =
                      sessions.map((Session s) => ActivityListItem(session: s, owner: 'You')).toList();
                  return ActivityList(
                    items: items,
                    onTap: (Session s) {
                      final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
                      vm.editPastSession(s.id);
                      Navigator.of(context).push(
                        MaterialPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                      );
                    },
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<Widget>(
                      builder: (_) => const AllSessionsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Show all'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


