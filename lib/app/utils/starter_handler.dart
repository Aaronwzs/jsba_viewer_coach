import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jsba_app/app/assets/firebase_options/firebase_options.dart';

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initApiServices();
}

Future<void> initApiServices() async {
  // Initialize services
}
