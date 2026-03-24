import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class CreateCoachingProgramPage extends StatelessWidget {
  const CreateCoachingProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Coaching Program')),
      body: const Center(child: Text('Create Coaching Program')),
    );
  }
}
