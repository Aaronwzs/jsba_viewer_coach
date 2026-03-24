import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class PlayerDetailsPage extends StatelessWidget {
  const PlayerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Details')),
      body: const Center(child: Text('Player Details')),
    );
  }
}
