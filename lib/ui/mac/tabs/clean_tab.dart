import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/ui/mac/widgets/aesthetic_spinner.dart';
import 'package:mole_ui/ui/mac/widgets/glass_action_widgets.dart';
import 'package:mole_ui/ui/mac/widgets/password_prompt_listener.dart';
import 'package:mole_ui/ui/widgets/activity_progress_panel.dart';

class CleanTab extends StatelessWidget {
  const CleanTab({super.key, required this.controller});

  final CleanController controller;

  @override
  Widget build(BuildContext context) {
    return PasswordPromptListener(
      listenable: controller,
      readPrompt: () => controller.passwordPrompt,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final isCleaning = controller.isCleaning;

          if (isCleaning) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AestheticSpinner(
                        isAnimating: true,
                        progress: controller.progress,
                        size: 72,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cleaning your Mac',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.passwordPrompt != null
                                  ? 'Waiting for administrator password...'
                                  : 'Removing junk safely, step by step',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF636366)
                                    .withValues(alpha: 0.95),
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
                        style: ActivityProgressStyle.mac,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  AestheticSpinner(
                    isAnimating: false,
                    progress: controller.progress,
                    size: 300,
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Ready to clean',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Free up space and speed up your Mac',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 36),
                  GlassActionButton(
                    label: 'Clean Your Mac',
                    onPressed: controller.startCleaning,
                  ),
                  if (controller.resultMessage != null) ...[
                    const SizedBox(height: 16),
                    GlassActionSuccessText(
                      message: controller.resultMessage!,
                    ),
                  ],
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    GlassActionErrorText(message: controller.errorMessage!),
                  ],
                ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
