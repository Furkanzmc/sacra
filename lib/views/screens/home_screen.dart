import 'package:flutter/material.dart';
import '../widgets/adaptive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: const Text('Home'),
      body: const Center(child: Text('Welcome')),
    );
  }
}


