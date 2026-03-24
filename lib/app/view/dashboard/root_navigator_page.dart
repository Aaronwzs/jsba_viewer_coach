import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class RootNavigatorPage extends StatelessWidget {
  const RootNavigatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Root Navigator')),
      body: const Center(child: Text('Root Navigator')),
    );
  }
}
