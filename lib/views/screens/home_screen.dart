import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/adaptive.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../theme/app_theme.dart';
// importing session_log_screen for consistency; replicate list inline to avoid private symbol issues
import 'active_session_screen.dart';
import '../../models/session.dart';
import '../../models/activity.dart';

String _homeClimbTypeLabel(ClimbType t) {
  switch (t) {
    case ClimbType.bouldering:
      return 'Bouldering';
    case ClimbType.topRope:
      return 'Top Rope';
    case ClimbType.lead:
      return 'Leading';
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionLogProvider); // Observe changes to refresh Home
    return AdaptiveScaffold(
      title: const Text('Home'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Stats placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Active session entry removed; Start handled via nav bar
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _HomeSessions()),
          ],
        ),
      ),
    );
  }
}

class _HomeSessions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Session> sessions = ref.watch(sessionLogProvider).pastSessions;
    if (sessions.isEmpty) {
      return const Center(child: Text('No past sessions'));
    }
    // Inline list to avoid private symbol export issues
    return _InlinePastSessionsList(sessions: sessions);
  }
}

class _InlinePastSessionsList extends ConsumerWidget {
  const _InlinePastSessionsList({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reuse Sessions grid renderer by pushing into a lightweight widget here
    return _ProxyPastSessionsList(sessions: sessions);
  }
}

class _ProxyPastSessionsList extends ConsumerWidget {
  const _ProxyPastSessionsList({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No past sessions'));
    }
    return GridView.builder(
      itemCount: sessions.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (BuildContext context, int index) {
        final Session s = sessions[index];
        final DateTime recorded = s.endTime ?? s.startTime;
        final String date = adaptiveFormatDate(context, recorded);
        final String time = adaptiveFormatTime(context, recorded);
        final int count = s.attempts.length;
        return AdaptiveCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () {
            final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);
            vm.editPastSession(s.id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (defaultTargetPlatform == TargetPlatform.iOS) {
                Navigator.of(context).push(
                  CupertinoPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(builder: (_) => ActiveSessionScreen(session: s)),
                );
              }
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _homeClimbTypeLabel(s.climbType),
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('$date • $time'),
              Text('$count routes'),
            ],
          ),
        );
      },
    );
  }
}


