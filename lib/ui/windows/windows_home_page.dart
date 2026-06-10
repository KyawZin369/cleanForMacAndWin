import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/home_controller.dart';

class WindowsHomePage extends StatelessWidget {
  const WindowsHomePage({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: Column(
            children: [
              _WindowsTitleBar(statusMessage: controller.statusMessage),
              Expanded(
                child: Row(
                  children: [
                    _WindowsNavPane(),
                    Expanded(
                      child: _WindowsContent(controller: controller),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WindowsTitleBar extends StatelessWidget {
  const _WindowsTitleBar({required this.statusMessage});

  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0078D4),
      ),
      child: Row(
        children: [
          const Text(
            'Mole UI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            statusMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowsNavPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFFF9F9F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Navigation',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF605E5C),
              ),
            ),
          ),
          _NavPaneItem(icon: Icons.home_outlined, label: 'Home', selected: true),
          _NavPaneItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            selected: false,
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Windows UI',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF8A8886),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPaneItem extends StatelessWidget {
  const _NavPaneItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE1DFDD) : null,
        border: Border(
          left: BorderSide(
            color: selected ? const Color(0xFF0078D4) : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? const Color(0xFF0078D4) : const Color(0xFF605E5C),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? const Color(0xFF323130) : const Color(0xFF605E5C),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowsContent extends StatelessWidget {
  const _WindowsContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome to Mole',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF323130),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Shared logic, Windows-native layout',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF605E5C),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F2F1),
                  border: Border.all(color: const Color(0xFFEDEBE9)),
                ),
                child: Text(
                  '${controller.counter}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF0078D4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _WindowsButton(
                      label: 'Decrease',
                      onPressed: controller.decrement,
                      secondary: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _WindowsButton(
                      label: 'Increase',
                      onPressed: controller.increment,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _WindowsButton(
                      label: 'Reset',
                      onPressed: controller.reset,
                      secondary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowsButton extends StatelessWidget {
  const _WindowsButton({
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor:
            secondary ? const Color(0xFFEDEBE9) : const Color(0xFF0078D4),
        foregroundColor:
            secondary ? const Color(0xFF323130) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      child: Text(label),
    );
  }
}
