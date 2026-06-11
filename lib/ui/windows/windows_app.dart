import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';
import 'package:mole_ui/core/logic/winmole_gate_controller.dart';
import 'package:mole_ui/ui/widgets/app_splash_screen.dart';
import 'package:mole_ui/ui/windows/pages/winmole_install_page.dart';
import 'package:mole_ui/ui/windows/windows_home_page.dart';

class WindowsApp extends StatefulWidget {
  const WindowsApp({
    super.key,
    required this.cleanController,
    required this.optimizeController,
    required this.uninstallController,
    required this.analyzeController,
    required this.statusController,
  });

  final CleanController cleanController;
  final OptimizeController optimizeController;
  final UninstallController uninstallController;
  final AnalyzeController analyzeController;
  final StatusController statusController;

  @override
  State<WindowsApp> createState() => _WindowsAppState();
}

class _WindowsAppState extends State<WindowsApp> {
  late final WinMoleGateController _gateController;
  late final Future<void> _startupFuture;
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _gateController = WinMoleGateController();
    _startupFuture = _gateController.check();
  }

  @override
  void dispose() {
    _gateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F2F1),
      ),
      home: _splashComplete ? _buildMainContent() : _buildSplash(),
    );
  }

  Widget _buildSplash() {
    return AppSplashScreen(
      waitFor: _startupFuture,
      onFinished: () {
        if (mounted) setState(() => _splashComplete = true);
      },
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _gateController,
      builder: (context, _) {
        if (_gateController.isReady) {
          return WindowsHomePage(
            cleanController: widget.cleanController,
            optimizeController: widget.optimizeController,
            uninstallController: widget.uninstallController,
            analyzeController: widget.analyzeController,
            statusController: widget.statusController,
          );
        }

        return WinMoleInstallPage(controller: _gateController);
      },
    );
  }
}
