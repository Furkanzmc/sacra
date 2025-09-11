import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/screens/activity_log_screen.dart';
import 'views/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sacra',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const ActivityLogScreen(),
    );
  }
}
