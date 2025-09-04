import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes.dart';
import 'bindings.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Check-In App',
      debugShowCheckedModeBanner: false,
      initialBinding: GlobalBindings(),
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
    );
  }
}
