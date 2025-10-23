import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'active_session_screen.dart';
import 'session_log_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/navigation_scope.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int _index = 0;
  final GlobalKey<NavigatorState> _sessionsKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _activeKey = GlobalKey<NavigatorState>();
  final CupertinoTabController _cupertinoController = CupertinoTabController(initialIndex: 0);
  final GlobalKey<NavigatorState> _homeKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final bool isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (isCupertino) {
      return NavigationScope(
        setTab: (int i) {
          _cupertinoController.index = i;
          setState(() => _index = i);
        },
        child: CupertinoTabScaffold(
          controller: _cupertinoController,
          tabBar: CupertinoTabBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: 'Sessions'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.play_fill), label: 'Active'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_crop_circle), label: 'Profile'),
            ],
          ),
          tabBuilder: (BuildContext context, int i) {
            switch (i) {
              case 0:
                return CupertinoTabView(
                  navigatorKey: _homeKey,
                  routes: <String, WidgetBuilder>{
                    '/': (_) => const HomeScreen(),
                  },
                );
              case 1:
                return CupertinoTabView(
                  navigatorKey: _sessionsKey,
                  routes: <String, WidgetBuilder>{
                    '/': (_) => const SessionLogScreen(),
                  },
                );
              case 2:
                return CupertinoTabView(
                  navigatorKey: _activeKey,
                  routes: <String, WidgetBuilder>{
                    '/': (_) => const ActiveSessionScreen(),
                  },
                );
              case 3:
              default:
                return CupertinoTabView(
                  navigatorKey: _profileKey,
                  routes: <String, WidgetBuilder>{
                    '/': (_) => const ProfileScreen(),
                  },
                );
            }
          },
        ),
      );
    }

    return NavigationScope(
      setTab: (int i) => setState(() => _index = i),
      child: Scaffold(
        body: () {
          switch (_index) {
            case 0:
              return const HomeScreen();
            case 1:
              return const SessionLogScreen();
            case 2:
              return const ActiveSessionScreen();
            case 3:
            default:
              return const ProfileScreen();
          }
        }(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.list), label: 'Sessions'),
            NavigationDestination(icon: Icon(Icons.play_arrow), label: 'Active'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onDestinationSelected: (int i) => setState(() => _index = i),
        ),
      ),
    );
  }
}


