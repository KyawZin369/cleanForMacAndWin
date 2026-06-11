import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/ui/widgets/activity_progress_panel.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';
import 'package:mole_ui/ui/windows/widgets/windows_spinner.dart';

class WindowsCleanTab extends StatelessWidget {
  const WindowsCleanTab({super.key, required this.controller});

  final CleanController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isCleaning = controller.isCleaning;

        if (isCleaning) {
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
                            'Cleaning your PC',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF323130),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Removing junk safely, step by step',
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
                      title: 'Cleanup steps',
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
                    'Ready to clean',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF323130),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Free up space and remove system junk',
                    style: TextStyle(fontSize: 14, color: Color(0xFF605E5C)),
                  ),
                  const SizedBox(height: 32),
                  WindowsPrimaryButton(
                    label: 'Clean Your PC',
                    expanded: true,
                    onPressed: controller.startCleaning,
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
