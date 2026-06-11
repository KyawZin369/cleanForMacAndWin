import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/core/logic/mole_cli_gate_controller.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';
import 'package:mole_ui/ui/mac/mac_home_page.dart';
import 'package:mole_ui/ui/mac/pages/mole_cli_install_page.dart';
import 'package:mole_ui/ui/widgets/app_splash_screen.dart';

class MacApp extends StatefulWidget {
  const MacApp({
    super.key,
    required this.cleanController,
    required this.uninstallController,
    required this.optimizeController,
    required this.analyzeController,
    required this.statusController,
  });

  final CleanController cleanController;
  final UninstallController uninstallController;
  final OptimizeController optimizeController;
  final AnalyzeController analyzeController;
  final StatusController statusController;

  @override
  State<MacApp> createState() => _MacAppState();
}

class _MacAppState extends State<MacApp> {
  late final MoleCliGateController _gateController;
  late final Future<void> _startupFuture;
  bool _splashComplete = false;

  @override
  void initState() {
    super.initState();
    _gateController = MoleCliGateController();
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
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
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
          return MacHomePage(
            cleanController: widget.cleanController,
            uninstallController: widget.uninstallController,
            optimizeController: widget.optimizeController,
            analyzeController: widget.analyzeController,
            statusController: widget.statusController,
          );
        }

        return MoleCliInstallPage(controller: _gateController);
      },
    );
  }
}
