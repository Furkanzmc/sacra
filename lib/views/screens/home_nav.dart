import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/navigation_scope.dart';
import '../../viewmodels/session_log_view_model.dart';
import 'active_session_screen.dart';

class HomeNav extends ConsumerStatefulWidget {
  const HomeNav({super.key});

  @override
  ConsumerState<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends ConsumerState<HomeNav> {
  int _index = 0;
  final CupertinoTabController _cupertinoController = CupertinoTabController(initialIndex: 0);
  final GlobalKey<NavigatorState> _homeKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final bool isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (isCupertino) {
      final bool hasActive = ref.watch(sessionLogProvider).activeSession != null;
      final Widget tabs = NavigationScope(
        setTab: (int i) {
          _cupertinoController.index = i;
          setState(() => _index = i);
        },
        child: CupertinoTabScaffold(
          controller: _cupertinoController,
          tabBar: CupertinoTabBar(
            onTap: (int i) async {
              if (i == 1) {
                await _handleStartSession(context);
                _cupertinoController.index = _index; // keep current tab
              } else {
                setState(() => _index = i);
              }
            },
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    const Icon(CupertinoIcons.play_fill),
                    if (hasActive)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: CupertinoColors.activeBlue, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                label: hasActive ? 'Continue' : 'Start',
              ),
              const BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle), label: 'Profile'),
            ],
          ),
          tabBuilder: (BuildContext context, int i) {
            if (i == 0) {
              return CupertinoTabView(
                navigatorKey: _homeKey,
                routes: <String, WidgetBuilder>{
                  '/': (_) => const HomeScreen(),
                },
              );
            }
            if (i == 2) {
              return CupertinoTabView(
                navigatorKey: _profileKey,
                routes: <String, WidgetBuilder>{
                  '/': (_) => ProfileScreen(),
                },
              );
            }
            // Start tab placeholder
            return const SizedBox.shrink();
          },
        ),
      );
      return tabs;
    }

    final bool hasActive = ref.watch(sessionLogProvider).activeSession != null;
    final Widget shell = NavigationScope(
      setTab: (int i) => setState(() => _index = i),
      child: Scaffold(
        body: _index == 0 ? const HomeScreen() : ProfileScreen(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: <NavigationDestination>[
            const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: hasActive,
                smallSize: 8,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.play_arrow),
              ),
              label: hasActive ? 'Continue' : 'Start',
            ),
            const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onDestinationSelected: (int i) async {
            if (i == 1) {
              await _handleStartSession(context);
              return;
            }
            setState(() => _index = i);
          },
        ),
      ),
    );
    return shell;
  }

  Future<void> _handleStartSession(BuildContext context) async {
    // Always navigate to the ActiveSessionScreen. That screen shows
    // in-page activity buttons when there is no active session.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Navigator.of(context).push(CupertinoPageRoute<Widget>(builder: (_) => const ActiveSessionScreen()));
    } else {
      await Navigator.of(context).push(MaterialPageRoute<Widget>(builder: (_) => const ActiveSessionScreen()));
    }
  }
}

// Previously: _ActiveSessionBanner (removed per latest design)


