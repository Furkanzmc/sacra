import 'package:flutter/widgets.dart';

class NavigationScope extends InheritedWidget {
  const NavigationScope({super.key, required this.setTab, required super.child});

  final void Function(int index) setTab;

  static NavigationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavigationScope>();
  }

  @override
  bool updateShouldNotify(NavigationScope oldWidget) => setTab != oldWidget.setTab;
}


