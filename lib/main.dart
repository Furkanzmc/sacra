import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/screens/home_nav.dart';
import 'views/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final bool isCupertino = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    if (isCupertino) {
      return const CupertinoApp(
        title: 'Sacra',
        home: HomeNav(),
      );
    }
    return MaterialApp(
      title: 'Sacra',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeNav(),
    );
  }
}
