import 'package:flutter/material.dart';
import 'package:jsba_app/app/utils/starter_handler.dart';
import 'package:jsba_app/app/view/app.dart';

Future<void> main() async {
  await init();
  runApp(const App());
}
