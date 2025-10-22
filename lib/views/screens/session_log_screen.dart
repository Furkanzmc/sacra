import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: unused_import
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

// Removed unused run icon helper after moving start controls to Active tab.

class SessionLogScreen extends ConsumerWidget {
  const SessionLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionLogState state = ref.watch(sessionLogProvider);
    // ViewModel not needed here after removing start controls from app bar.

    // Active session navigation is available via bottom navigation.

    return AdaptiveScaffold(
      title: const Text('Session Log'),
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


class _PastSessionsList extends ConsumerWidget {
  const _PastSessionsList({required this.sessions});

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
              if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
                showCupertinoSheet(
                  context: context,
                  builder: (_) => const ActiveSessionScreen(),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(builder: (_) => const ActiveSessionScreen()),
                );
              }
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                s.climbType.name,
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


