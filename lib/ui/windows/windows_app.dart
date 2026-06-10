import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/home_controller.dart';
import 'package:mole_ui/ui/windows/windows_home_page.dart';

class WindowsApp extends StatelessWidget {
  const WindowsApp({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mole UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F3F3),
      ),
      home: WindowsHomePage(controller: controller),
    );
  }
}
