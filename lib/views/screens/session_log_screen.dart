import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/activity.dart';
import '../../models/session.dart';
import '../../viewmodels/session_log_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import 'active_session_screen.dart';
import '../widgets/adaptive.dart';
IconData _adaptivePlayIcon() {
  return (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
      ? CupertinoIcons.play_fill
      : Icons.play_arrow;
}

IconData _adaptiveRunIcon() {
  return (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
      ? CupertinoIcons.person_2_fill
      : Icons.directions_run;
}

class SessionLogScreen extends ConsumerWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionLogState state = ref.watch(sessionLogProvider);
    final SessionLogViewModel vm = ref.read(sessionLogProvider.notifier);

    // Active session navigation is available via bottom navigation.

    return AdaptiveScaffold(
      title: const Text('Session Log'),
      actions: <Widget>[
        if (state.activeSession == null)
          if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
            AdaptiveIconButton(
              icon: const Icon(CupertinoIcons.play_fill),
              tooltip: 'Start Session',
              onPressed: () async {
                await showAdaptiveActionSheet<ClimbType>(
                  context: context,
                  title: 'Start Session',
                  items: <MapEntry<ClimbType, String>>[
                    MapEntry<ClimbType, String>(ClimbType.bouldering, 'Start Bouldering'),
                    MapEntry<ClimbType, String>(ClimbType.topRope, 'Start Top Rope'),
                    MapEntry<ClimbType, String>(ClimbType.lead, 'Start Lead'),
                  ],
                  onSelected: (ClimbType t) => vm.startSession(t),
                );
              },
            )
          else
            PopupMenuButton<ClimbType>(
              onSelected: (ClimbType t) => vm.startSession(t),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ClimbType>>[
                const PopupMenuItem<ClimbType>(
                  value: ClimbType.bouldering,
                  child: Text('Start Bouldering'),
                ),
                const PopupMenuItem<ClimbType>(
                  value: ClimbType.topRope,
                  child: Text('Start Top Rope'),
                ),
                const PopupMenuItem<ClimbType>(
                  value: ClimbType.lead,
                  child: Text('Start Lead'),
                ),
              ],
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start Session',
            )
        else
          AdaptiveIconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<Widget>(
                  builder: (_) => const ActiveSessionScreen(),
                ),
              );
            },
            tooltip: 'Go to Active Session',
            icon: Icon(_adaptiveRunIcon()),
          ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.constrainedWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (state.activeSession == null)
                  const _EmptyPrompt()
                else
                  _ActiveSessionButton(),
                const SizedBox(height: AppSpacing.lg),
                Text('Past Sessions', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _PastSessionsList(sessions: state.pastSessions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'No active session. Use the Play button in the app bar to start.',
      ),
    );
  }
}

class _ActiveSessionButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session? session = ref.watch(sessionLogProvider).activeSession;
    if (session == null) {
      return const SizedBox.shrink();
    }
    return AdaptiveFilledButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<Widget>(
            builder: (_) => const ActiveSessionScreen(),
          ),
        );
      },
      icon: Icon(_adaptivePlayIcon()),
      label: Text('Resume ${session.climbType.name} session'),
    );
  }
}


class _PastSessionsList extends StatelessWidget {
  const _PastSessionsList({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No past sessions'));
    }
    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final Session s = sessions[index];
        final DateTime recorded = s.endTime ?? s.startTime;
        final String when = adaptiveFormatDate(context, recorded);
        final int count = s.attempts.length;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${s.climbType.name} • $when • $count attempts'),
        );
      },
    );
  }
}


