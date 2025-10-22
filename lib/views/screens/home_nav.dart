import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'active_session_screen.dart';
import 'session_log_screen.dart';
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
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: 'Sessions'),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.play_fill), label: 'Active'),
            ],
          ),
          tabBuilder: (BuildContext context, int i) {
            if (i == 0) {
              return CupertinoTabView(
                navigatorKey: _sessionsKey,
                routes: <String, WidgetBuilder>{
                  '/': (_) => const SessionLogScreen(),
                },
              );
            }
            return CupertinoTabView(
              navigatorKey: _activeKey,
              routes: <String, WidgetBuilder>{
                '/': (_) => const ActiveSessionScreen(),
              },
            );
          },
        ),
      );
    }

    return NavigationScope(
      setTab: (int i) => setState(() => _index = i),
      child: Scaffold(
        body: _index == 0 ? const SessionLogScreen() : const ActiveSessionScreen(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.list), label: 'Sessions'),
            NavigationDestination(icon: Icon(Icons.play_arrow), label: 'Active'),
          ],
          onDestinationSelected: (int i) => setState(() => _index = i),
        ),
      ),
    );
  }
}


