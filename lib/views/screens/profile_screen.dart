import 'package:flutter/material.dart';
import '../widgets/adaptive.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: const Text('Profile'),
      body: const Center(child: Text('Your profile')), 
    );
  }
}


