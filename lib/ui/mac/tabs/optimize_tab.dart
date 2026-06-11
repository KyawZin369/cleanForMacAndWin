import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/optimize_controller.dart';
import 'package:mole_ui/ui/mac/widgets/aesthetic_spinner.dart';
import 'package:mole_ui/ui/mac/widgets/glass_action_widgets.dart';
import 'package:mole_ui/ui/mac/widgets/password_prompt_listener.dart';

class OptimizeTab extends StatelessWidget {
  const OptimizeTab({super.key, required this.controller});

  final OptimizeController controller;

  @override
  Widget build(BuildContext context) {
    return PasswordPromptListener(
      listenable: controller,
      readPrompt: () => controller.passwordPrompt,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final isOptimizing = controller.isOptimizing;
          final awaitingPassword = controller.passwordPrompt != null;
          final progress = controller.progress;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AestheticSpinner(
                    isAnimating: isOptimizing || awaitingPassword,
                    progress: progress,
                    size: 300,
                  ),
                  const SizedBox(height: 48),
                  if (isOptimizing || awaitingPassword) ...[
                    GlassProgressSection(
                      progress: progress,
                      percent: controller.progressPercent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      awaitingPassword
                          ? 'Waiting for administrator password...'
                          : 'Optimizing your Mac...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Ready to optimize',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Refresh caches and tune system services',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 36),
                  GlassActionButton(
                    label: 'Optimize Your Mac',
                    onPressed: controller.startOptimizing,
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
