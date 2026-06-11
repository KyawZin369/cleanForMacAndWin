import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
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

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WindowsSpinner(
                    isAnimating: isCleaning,
                    progress: controller.progress,
                    size: 280,
                  ),
                  const SizedBox(height: 36),
                  if (isCleaning) ...[
                    WindowsProgressSection(
                      progress: controller.progress,
                      percent: controller.progressPercent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cleaning your PC...',
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF605E5C).withValues(alpha: 0.9),
                      ),
                    ),
                  ] else ...[
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
