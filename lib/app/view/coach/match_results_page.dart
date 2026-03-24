import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MatchResultsPage extends StatelessWidget {
  const MatchResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Results')),
      body: const Center(child: Text('Match Results')),
    );
  }
}
