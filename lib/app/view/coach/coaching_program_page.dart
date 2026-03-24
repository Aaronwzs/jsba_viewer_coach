import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class CoachingProgramPage extends StatelessWidget {
  const CoachingProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coaching Program')),
      body: const Center(child: Text('Coaching Program')),
    );
  }
}
