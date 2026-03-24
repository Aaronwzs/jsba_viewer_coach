import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ChildDetailsPage extends StatelessWidget {
  const ChildDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Child Details')),
      body: const Center(child: Text('Child Details')),
    );
  }
}
