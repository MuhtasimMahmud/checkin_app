import 'package:checkin_app/src/core/location_permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/app/main_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Force location permission + GPS ON
  final contextKey = GlobalKey<NavigatorState>();
  runApp(MaterialApp(
    navigatorKey: contextKey,
    home: const Scaffold(body: Center(child: CircularProgressIndicator())),
  ));
  await Future.delayed(const Duration(milliseconds: 500));

  await LocationPermissionHelper.ensureLocationPermission(
      contextKey.currentContext!);

  // After permission is granted → load actual app
  runApp(const MainApp());
}
