import 'package:flutter/material.dart';
import 'package:mole_ui/app/app_router.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/core/logic/home_controller.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';

void main() {
  runApp(
    AppRouter(
      homeController: HomeController(),
      cleanController: CleanController(),
      uninstallController: UninstallController(),
      optimizeController: OptimizeController(),
      analyzeController: AnalyzeController(),
      statusController: StatusController(),
    ),
  );
}
