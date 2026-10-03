import 'package:flutter/material.dart';
import 'package:gutgood/app/app.dart';
import 'package:gutgood/app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const GutGoodApp());
}
