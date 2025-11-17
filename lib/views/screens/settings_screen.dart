import 'package:flutter/material.dart';
import '../widgets/adaptive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScaffold(
      title: Text('Settings'),
      body: Center(child: Text('Settings coming soon')),
    );
  }
}


