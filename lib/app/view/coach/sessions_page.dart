import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jsba_app/app/widgets/app_bar_title.dart';

@RoutePage()
class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarTitle(),
      body: const Center(child: Text('Sessions')),
    );
  }
}
