import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'active_session_screen.dart';
import 'session_log_screen.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final bool isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final List<Widget> pages = <Widget>[
      const SessionLogScreen(),
      const ActiveSessionScreen(),
    ];

    if (isCupertino) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.list_bullet), label: 'Sessions'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.play_fill), label: 'Active'),
          ],
        ),
        tabBuilder: (BuildContext context, int i) => CupertinoTabView(
          builder: (_) => pages[i],
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.list), label: 'Sessions'),
          NavigationDestination(icon: Icon(Icons.play_arrow), label: 'Active'),
        ],
        onDestinationSelected: (int i) => setState(() => _index = i),
      ),
    );
  }
}


