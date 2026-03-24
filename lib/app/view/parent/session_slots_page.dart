import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SessionSlotsPage extends StatelessWidget {
  const SessionSlotsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Slots')),
      body: const Center(child: Text('Session Slots')),
    );
  }
}
