import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class AnnouncementDetailsPage extends StatelessWidget {
  const AnnouncementDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcement Details')),
      body: const Center(child: Text('Announcement Details')),
    );
  }
}
