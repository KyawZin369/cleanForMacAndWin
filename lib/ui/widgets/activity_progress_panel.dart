import 'package:flutter/material.dart';
import 'package:mole_ui/core/logic/cli_activity.dart';

enum ActivityProgressStyle { mac, windows }

class ActivityProgressPanel extends StatelessWidget {
  const ActivityProgressPanel({
    super.key,
    required this.sections,
    required this.progress,
    required this.percent,
    required this.style,
    this.currentActivityLabel,
    this.title = 'Progress',
  });

  final List<ActivitySection> sections;
  final double progress;
  final int percent;
  final ActivityProgressStyle style;
  final String? currentActivityLabel;
  final String title;

  bool get _isMac => style == ActivityProgressStyle.mac;

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      isMac: _isMac,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isMac: _isMac,
            title: title,
            percent: percent,
            currentActivityLabel: currentActivityLabel,
          ),
          const SizedBox(height: 14),
          _ProgressBar(progress: progress, isMac: _isMac),
          const SizedBox(height: 18),
          if (sections.isEmpty)
            _WaitingRow(isMac: _isMac)
          else
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SectionRow(section: section, isMac: _isMac),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.isMac, required this.child});

  final bool isMac;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isMac) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.82),
              Colors.white.withValues(alpha: 0.68),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFEDEBE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isMac,
    required this.title,
    required this.percent,
    required this.currentActivityLabel,
  });

  final bool isMac;
  final String title;
  final int percent;
  final String? currentActivityLabel;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isMac ? const Color(0xFF1C1C1E) : const Color(0xFF323130);
    final subtitleColor =
        isMac ? const Color(0xFF636366) : const Color(0xFF605E5C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: titleColor,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMac ? const Color(0xFF007AFF) : const Color(0xFF0078D4),
              ),
            ),
          ],
        ),
        if (currentActivityLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            currentActivityLabel!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: subtitleColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.isMac});

  final double progress;
  final bool isMac;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isMac ? 8 : 2),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: isMac
                  ? Colors.black.withValues(alpha: 0.06)
                  : const Color(0xFFEDEBE9),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMac
                        ? const [
                            Color(0xFF5AC8FA),
                            Color(0xFF007AFF),
                            Color(0xFF5856D6),
                          ]
                        : const [
                            Color(0xFF2B88D8),
                            Color(0xFF0078D4),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({required this.isMac});

  final bool isMac;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusDot(status: ActivitySectionStatus.active, isMac: isMac),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Preparing your system scan...',
            style: TextStyle(
              fontSize: 14,
              color: isMac ? const Color(0xFF636366) : const Color(0xFF605E5C),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.section, required this.isMac});

  final ActivitySection section;
  final bool isMac;

  @override
  Widget build(BuildContext context) {
    final titleColor = switch (section.status) {
      ActivitySectionStatus.pending =>
        isMac ? const Color(0xFF8E8E93) : const Color(0xFFA19F9D),
      _ => isMac ? const Color(0xFF1C1C1E) : const Color(0xFF323130),
    };

    final recentItems = section.items.reversed.take(2).toList().reversed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: section.status == ActivitySectionStatus.active
            ? (isMac
                ? const Color(0xFF007AFF).withValues(alpha: 0.06)
                : const Color(0xFF0078D4).withValues(alpha: 0.05))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isMac ? 12 : 4),
        border: section.status == ActivitySectionStatus.active
            ? Border.all(
                color: isMac
                    ? const Color(0xFF007AFF).withValues(alpha: 0.14)
                    : const Color(0xFF0078D4).withValues(alpha: 0.18),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusDot(status: section.status, isMac: isMac),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          section.icon,
                          size: 15,
                          color: titleColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            section.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: section.status ==
                                      ActivitySectionStatus.active
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.statusSummary ?? section.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isMac
                            ? const Color(0xFF636366)
                            : const Color(0xFF605E5C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (recentItems.isNotEmpty &&
              section.status == ActivitySectionStatus.active) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in recentItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _ItemChip(item: item, isMac: isMac),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.item, required this.isMac});

  final ActivityItem item;
  final bool isMac;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.status) {
      ActivityItemStatus.completed => (
          Icons.check_rounded,
          isMac ? const Color(0xFF34C759) : const Color(0xFF107C10),
        ),
      ActivityItemStatus.warning => (
          Icons.info_outline_rounded,
          isMac ? const Color(0xFFFF9500) : const Color(0xFFCA5010),
        ),
      ActivityItemStatus.skipped => (
          Icons.remove_rounded,
          const Color(0xFF8E8E93),
        ),
      ActivityItemStatus.active => (
          Icons.autorenew_rounded,
          isMac ? const Color(0xFF007AFF) : const Color(0xFF0078D4),
        ),
    };

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMac ? const Color(0xFF48484A) : const Color(0xFF605E5C),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, required this.isMac});

  final ActivitySectionStatus status;
  final bool isMac;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: switch (status) {
        ActivitySectionStatus.completed => Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: isMac ? const Color(0xFF34C759) : const Color(0xFF107C10),
          ),
        ActivitySectionStatus.skipped => Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: isMac ? const Color(0xFF8E8E93) : const Color(0xFFA19F9D),
          ),
        ActivitySectionStatus.active => _PulsingDot(isMac: isMac),
        ActivitySectionStatus.pending => Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMac
                    ? const Color(0xFFD1D1D6)
                    : const Color(0xFFC8C6C4),
                width: 2,
              ),
            ),
          ),
      },
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.isMac});

  final bool isMac;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isMac ? const Color(0xFF007AFF) : const Color(0xFF0078D4);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.85 + (_controller.value * 0.15);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
