import 'package:flutter/material.dart';

enum WindowsHomeSection {
  clean('Clean', Icons.cleaning_services_outlined),
  optimize('Optimize', Icons.tune_outlined),
  uninstall('Uninstall', Icons.delete_outline),
  analyze('Analyze', Icons.pie_chart_outline),
  status('Status', Icons.monitor_heart_outlined);

  const WindowsHomeSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class WindowsCard extends StatelessWidget {
  const WindowsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEDEBE9)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class WindowsPrimaryButton extends StatelessWidget {
  const WindowsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0078D4),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFC8C6C4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Text(label),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class WindowsSecondaryButton extends StatelessWidget {
  const WindowsSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF323130),
        side: const BorderSide(color: Color(0xFF8A8886)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      child: Text(label),
    );
  }
}

class WindowsProgressSection extends StatelessWidget {
  const WindowsProgressSection({
    super.key,
    required this.progress,
    required this.percent,
  });

  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return WindowsCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFEDEBE9),
              color: const Color(0xFF0078D4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percent% complete',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF605E5C),
            ),
          ),
        ],
      ),
    );
  }
}

class WindowsMessageBanner extends StatelessWidget {
  const WindowsMessageBanner.success({super.key, required this.message})
      : color = const Color(0xFF107C10),
        background = const Color(0xFFDFF6DD);

  const WindowsMessageBanner.error({super.key, required this.message})
      : color = const Color(0xFFA4262C),
        background = const Color(0xFFFDE7E9);

  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: color, height: 1.35),
      ),
    );
  }
}

class WindowsNavPane extends StatelessWidget {
  const WindowsNavPane({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WindowsHomeSection selected;
  final ValueChanged<WindowsHomeSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFFF3F2F1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Tools',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF605E5C),
              ),
            ),
          ),
          for (final section in WindowsHomeSection.values)
            _NavItem(
              icon: section.icon,
              label: section.label,
              selected: section == selected,
              onTap: () => onSelected(section),
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Powered by WinMole',
              style: TextStyle(fontSize: 11, color: Color(0xFF8A8886)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEDEBE9) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
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
                color: selected
                    ? const Color(0xFF0078D4)
                    : const Color(0xFF605E5C),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? const Color(0xFF323130)
                      : const Color(0xFF605E5C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
