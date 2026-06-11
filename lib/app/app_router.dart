import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';
import 'package:mole_ui/core/platform/platform_info.dart';
import 'package:mole_ui/ui/mac/mac_app.dart';
import 'package:mole_ui/ui/windows/windows_app.dart';

/// Picks the correct platform UI while sharing the same business logic.
class AppRouter extends StatelessWidget {
  const AppRouter({
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
  Widget build(BuildContext context) {
    switch (currentPlatform) {
      case AppPlatform.mac:
        return MacApp(
          cleanController: cleanController,
          uninstallController: uninstallController,
          optimizeController: optimizeController,
          analyzeController: analyzeController,
          statusController: statusController,
        );
      case AppPlatform.windows:
        return WindowsApp(
          cleanController: cleanController,
          uninstallController: uninstallController,
          analyzeController: analyzeController,
          statusController: statusController,
        );
      case AppPlatform.unsupported:
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'This app only supports macOS and Windows.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
    }
  }
}
