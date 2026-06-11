import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mole_ui/core/logic/winmole_gate_controller.dart';
import 'package:mole_ui/ui/widgets/app_logo.dart';
import 'package:mole_ui/ui/windows/widgets/fluent_widgets.dart';

class WinMoleInstallPage extends StatelessWidget {
  const WinMoleInstallPage({super.key, required this.controller});

  final WinMoleGateController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2F1),
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: WindowsCard(
                  child: switch (controller.phase) {
                    WinMoleGatePhase.checking => const _CheckingBody(),
                    WinMoleGatePhase.needsInstall ||
                    WinMoleGatePhase.waitingForInstall =>
                      _InstallBody(controller: controller),
                    WinMoleGatePhase.ready => const SizedBox.shrink(),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckingBody extends StatelessWidget {
  const _CheckingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: 56, showShadow: false),
        SizedBox(height: 20),
        CircularProgressIndicator(strokeWidth: 2.5),
        SizedBox(height: 16),
        Text(
          'Checking for WinMole…',
          style: TextStyle(fontSize: 15, color: Color(0xFF605E5C)),
        ),
      ],
    );
  }
}

class _InstallBody extends StatelessWidget {
  const _InstallBody({required this.controller});

  final WinMoleGateController controller;

  @override
  Widget build(BuildContext context) {
    final waiting = controller.phase == WinMoleGatePhase.waitingForInstall;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AppLogo(size: 56, showShadow: false)),
        const SizedBox(height: 16),
        Text(
          controller.bundledRuntimeAvailable
              ? 'Install WinMole CLI'
              : 'WinMole Runtime Missing',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF323130),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          controller.bundledRuntimeAvailable
              ? 'Khine bundles WinMole, but the runtime was not detected. Install it with PowerShell or vendor it with scripts/setup_winmole_vendor.sh.'
              : 'Run scripts/setup_winmole_vendor.sh, then rebuild the Windows app so WinMole is bundled.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF605E5C), height: 1.4),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F2F1),
            border: Border.all(color: const Color(0xFFEDEBE9)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: SelectableText(
            controller.installCommand,
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 13,
              color: Color(0xFF323130),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: controller.installCommand),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy command'),
          ),
        ),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 12),
          WindowsMessageBanner.error(message: controller.errorMessage!),
        ],
        const SizedBox(height: 16),
        WindowsPrimaryButton(
          label: waiting ? 'Waiting for install…' : 'Install in PowerShell',
          expanded: true,
          onPressed: waiting ? null : controller.installInPowerShell,
        ),
      ],
    );
  }
}
