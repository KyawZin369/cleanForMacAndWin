import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';
import 'package:mole_ui/ui/widgets/app_logo.dart';
import 'package:mole_ui/ui/windows/tabs/analyze_tab.dart';
import 'package:mole_ui/ui/windows/tabs/clean_tab.dart';
import 'package:mole_ui/ui/windows/tabs/optimize_tab.dart';
import 'package:mole_ui/ui/windows/tabs/status_tab.dart';
import 'package:mole_ui/ui/windows/tabs/uninstall_tab.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';

class WindowsHomePage extends StatefulWidget {
  const WindowsHomePage({
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
  State<WindowsHomePage> createState() => _WindowsHomePageState();
}

class _WindowsHomePageState extends State<WindowsHomePage> {
  WindowsHomeSection _selected = WindowsHomeSection.clean;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _WindowsTitleBar(),
          Expanded(
            child: Row(
              children: [
                WindowsNavPane(
                  selected: _selected,
                  onSelected: (section) => setState(() => _selected = section),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ColoredBox(
      color: Colors.white,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (_selected) {
          WindowsHomeSection.clean =>
            WindowsCleanTab(key: const ValueKey('clean'), controller: widget.cleanController),
          WindowsHomeSection.optimize => WindowsOptimizeTab(
              key: const ValueKey('optimize'),
              controller: widget.optimizeController,
            ),
          WindowsHomeSection.uninstall => WindowsUninstallTab(
              key: const ValueKey('uninstall'),
              controller: widget.uninstallController,
            ),
          WindowsHomeSection.analyze => WindowsAnalyzeTab(
              key: const ValueKey('analyze'),
              controller: widget.analyzeController,
            ),
          WindowsHomeSection.status =>
            WindowsStatusTab(key: const ValueKey('status'), controller: widget.statusController),
        },
      ),
    );
  }
}

class _WindowsTitleBar extends StatelessWidget {
  const _WindowsTitleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFF0078D4)),
      child: const Row(
        children: [
          AppLogo(size: 24, showShadow: false),
          SizedBox(width: 10),
          Text(
            'Khine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Text(
            'Windows',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
