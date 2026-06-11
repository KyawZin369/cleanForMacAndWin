import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/clean_controller.dart';
import 'package:mole_ui/ui/mac/widgets/aesthetic_spinner.dart';
import 'package:mole_ui/ui/mac/widgets/glass_action_widgets.dart';
import 'package:mole_ui/ui/mac/widgets/password_prompt_listener.dart';

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
          final progress = controller.progress;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AestheticSpinner(
                    isAnimating: isCleaning,
                    progress: progress,
                    size: 300,
                  ),
                  const SizedBox(height: 48),
                  if (isCleaning) ...[
                    GlassProgressSection(
                      progress: progress,
                      percent: controller.progressPercent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      controller.passwordPrompt != null
                          ? 'Waiting for administrator password...'
                          : 'Cleaning your Mac...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
                      ),
                    ),
                  ] else ...[
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
