import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/ui/widgets/activity_progress_panel.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';
import 'package:mole_ui/ui/windows/widgets/windows_spinner.dart';

class WindowsOptimizeTab extends StatelessWidget {
  const WindowsOptimizeTab({super.key, required this.controller});

  final OptimizeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isOptimizing = controller.isOptimizing;

        if (isOptimizing) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    WindowsSpinner(
                      isAnimating: true,
                      progress: controller.progress,
                      size: 64,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Optimizing your PC',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF323130),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tuning services and refreshing system caches',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF605E5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: ActivityProgressPanel(
                      sections: controller.activitySections,
                      progress: controller.progress,
                      percent: controller.progressPercent,
                      currentActivityLabel: controller.currentActivityLabel,
                      style: ActivityProgressStyle.windows,
                      title: 'Optimization tasks',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WindowsSpinner(
                    isAnimating: false,
                    progress: controller.progress,
                    size: 280,
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'Ready to optimize',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF323130),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Refresh caches, repair services, and tune performance',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF605E5C)),
                  ),
                  const SizedBox(height: 32),
                  WindowsPrimaryButton(
                    label: 'Optimize Your PC',
                    expanded: true,
                    onPressed: controller.startOptimizing,
                  ),
                  if (controller.resultMessage != null) ...[
                    const SizedBox(height: 16),
                    WindowsMessageBanner.success(
                      message: controller.resultMessage!,
                    ),
                  ],
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    WindowsMessageBanner.error(
                      message: controller.errorMessage!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
