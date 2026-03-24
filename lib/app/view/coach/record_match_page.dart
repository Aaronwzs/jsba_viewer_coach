import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class RecordMatchPage extends StatelessWidget {
  const RecordMatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Match')),
      body: const Center(child: Text('Record Match')),
    );
  }
}
