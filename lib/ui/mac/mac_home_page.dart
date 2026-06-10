import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/analyze_controller.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/core/logic/status_controller.dart';
import 'package:mole_ui/core/logic/uninstall_controller.dart';
import 'package:mole_ui/ui/mac/tabs/analyze_tab.dart';
import 'package:mole_ui/ui/mac/tabs/clean_tab.dart';
import 'package:mole_ui/ui/mac/tabs/optimize_tab.dart';
import 'package:mole_ui/ui/mac/tabs/status_tab.dart';
import 'package:mole_ui/ui/mac/tabs/uninstall_tab.dart';
import 'package:mole_ui/ui/mac/widgets/glass_action_widgets.dart';
import 'package:mole_ui/ui/mac/widgets/mac_tab_bar.dart';

class MacHomePage extends StatefulWidget {
  const MacHomePage({
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
  State<MacHomePage> createState() => _MacHomePageState();
}

class _MacHomePageState extends State<MacHomePage> {
  MacHomeTab _selectedTab = MacHomeTab.clean;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF2FF),
              Color(0xFFF4F0FF),
              Color(0xFFF5F5F7),
              Color(0xFFEEF6FF),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            MacTabBar(
              selectedTab: _selectedTab,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
            ),
            Expanded(
              child: GlassTabSwitcher(
                tabKey: _selectedTab,
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return switch (_selectedTab) {
      MacHomeTab.clean => CleanTab(controller: widget.cleanController),
      MacHomeTab.uninstall =>
        UninstallTab(controller: widget.uninstallController),
      MacHomeTab.optimize =>
        OptimizeTab(controller: widget.optimizeController),
      MacHomeTab.analyze =>
        AnalyzeTab(controller: widget.analyzeController),
      MacHomeTab.status => StatusTab(controller: widget.statusController),
    };
  }
}
