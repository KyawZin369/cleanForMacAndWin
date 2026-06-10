import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mole_ui/core/logic/mole_cli_gate_controller.dart';
import 'package:mole_ui/ui/mac/widgets/glass_action_widgets.dart';

class MoleCliInstallPage extends StatelessWidget {
  const MoleCliInstallPage({super.key, required this.controller});

  final MoleCliGateController controller;

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
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _InstallCard(controller: controller),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InstallCard extends StatelessWidget {
  const _InstallCard({required this.controller});

  final MoleCliGateController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: switch (controller.phase) {
            MoleCliGatePhase.checking => const _CheckingBody(),
            MoleCliGatePhase.needsInstall ||
            MoleCliGatePhase.waitingForInstall =>
              _InstallBody(controller: controller),
            MoleCliGatePhase.ready => const SizedBox.shrink(),
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
        CircularProgressIndicator(strokeWidth: 2.5),
        SizedBox(height: 20),
        Text(
          'Checking for Mole CLI…',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF636366),
          ),
        ),
      ],
    );
  }
}

class _InstallBody extends StatelessWidget {
  const _InstallBody({required this.controller});

  final MoleCliGateController controller;

  @override
  Widget build(BuildContext context) {
    final waiting = controller.phase == MoleCliGatePhase.waitingForInstall;
    final hasBrew = controller.homebrewInstalled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.terminal_rounded,
          size: 44,
          color: Color(0xFF007AFF),
        ),
        const SizedBox(height: 16),
        const Text(
          'Install Mole CLI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hasBrew
              ? 'This app needs the Mole command-line tool (`mo`) to clean, optimize, and monitor your Mac. Install it once with Homebrew, then you can use every feature in this app.'
              : 'Homebrew was not found on this Mac. Install Homebrew first, then install the Mole CLI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: const Color(0xFF636366).withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 20),
        if (hasBrew) ...[
          _CommandBlock(command: controller.brewInstallCommand),
          const SizedBox(height: 20),
        ] else ...[
          const _CommandBlock(
            command:
                r'/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
          ),
          const SizedBox(height: 12),
          Text(
            'After Homebrew is installed, return here and tap Check Again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF636366).withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (waiting) ...[
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(
                'Installing in Terminal…',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF636366),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the install in Terminal, then switch back here. This screen updates automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: const Color(0xFF636366).withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (controller.errorMessage != null) ...[
          GlassActionErrorText(message: controller.errorMessage!),
          const SizedBox(height: 16),
        ],
        if (hasBrew && !waiting)
          Center(
            child: GlassActionButton(
              label: 'Install in Terminal',
              onPressed: controller.installInTerminal,
            ),
          ),
        if (waiting || !hasBrew) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: controller.check,
              child: const Text('Check Again'),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommandBlock extends StatelessWidget {
  const _CommandBlock({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              command,
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontSize: 13,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy command',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
