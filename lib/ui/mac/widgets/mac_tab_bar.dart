import 'dart:ui';

import 'package:flutter/material.dart';

enum MacHomeTab {
  clean('Clean'),
  uninstall('Uninstall'),
  optimize('Optimize'),
  analyze('Analyze'),
  status('Status');

  const MacHomeTab(this.label);

  final String label;
}

class MacTabBar extends StatefulWidget {
  const MacTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final MacHomeTab selectedTab;
  final ValueChanged<MacHomeTab> onTabSelected;

  @override
  State<MacTabBar> createState() => _MacTabBarState();
}

class _MacTabBarState extends State<MacTabBar> {
  final _trackKey = GlobalKey();
  final _tabKeys =
      List<GlobalKey>.generate(MacHomeTab.values.length, (_) => GlobalKey());

  double _indicatorLeft = 0;
  double _indicatorWidth = 0;
  bool _indicatorReady = false;

  @override
  void initState() {
    super.initState();
    _scheduleIndicatorUpdate();
  }

  @override
  void didUpdateWidget(MacTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      _scheduleIndicatorUpdate();
    }
  }

  void _scheduleIndicatorUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  void _updateIndicator() {
    if (!mounted) return;

    final index = MacHomeTab.values.indexOf(widget.selectedTab);
    final tabBox =
        _tabKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final trackBox =
        _trackKey.currentContext?.findRenderObject() as RenderBox?;

    if (tabBox == null || trackBox == null || !tabBox.hasSize) {
      _scheduleIndicatorUpdate();
      return;
    }

    final offset = tabBox.localToGlobal(Offset.zero, ancestor: trackBox);
    setState(() {
      _indicatorLeft = offset.dx;
      _indicatorWidth = tabBox.size.width;
      _indicatorReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.68),
                Colors.white.withValues(alpha: 0.48),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 24),
              const _GlassLogo(),
              const SizedBox(width: 28),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _TabTrack(
                    trackKey: _trackKey,
                    indicatorLeft: _indicatorLeft,
                    indicatorWidth: _indicatorWidth,
                    indicatorReady: _indicatorReady,
                    children: [
                      for (var i = 0; i < MacHomeTab.values.length; i++)
                        _GlassTabItem(
                          key: _tabKeys[i],
                          label: MacHomeTab.values[i].label,
                          selected: MacHomeTab.values[i] == widget.selectedTab,
                          onTap: () => widget.onTabSelected(MacHomeTab.values[i]),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabTrack extends StatelessWidget {
  const _TabTrack({
    required this.trackKey,
    required this.indicatorLeft,
    required this.indicatorWidth,
    required this.indicatorReady,
    required this.children,
  });

  final GlobalKey trackKey;
  final double indicatorLeft;
  final double indicatorWidth;
  final bool indicatorReady;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: trackKey,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            left: indicatorLeft,
            top: 10,
            width: indicatorWidth,
            height: 36,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: indicatorReady ? 1 : 0,
              child: const _GlassSelectionPill(),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: children),
        ],
      ),
    );
  }
}

class _GlassSelectionPill extends StatelessWidget {
  const _GlassSelectionPill();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.92),
                Colors.white.withValues(alpha: 0.62),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007AFF).withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassLogo extends StatelessWidget {
  const _GlassLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5AC8FA), Color(0xFF5856D6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Khine',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}

class _GlassTabItem extends StatelessWidget {
  const _GlassTabItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF007AFF).withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: -0.1,
              color: selected
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF1C1C1E).withValues(alpha: 0.55),
            ),
            child: AnimatedScale(
              scale: selected ? 1.02 : 1,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
