import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mole_ui/ui/widgets/app_logo.dart';

class WindowsSpinner extends StatefulWidget {
  const WindowsSpinner({
    super.key,
    required this.isAnimating,
    this.progress = 0,
    this.size = 280,
  });

  final bool isAnimating;
  final double progress;
  final double size;

  @override
  State<WindowsSpinner> createState() => _WindowsSpinnerState();
}

class _WindowsSpinnerState extends State<WindowsSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant WindowsSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating != widget.isAnimating) {
      _sync();
    }
  }

  void _sync() {
    if (widget.isAnimating) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showProgress = widget.isAnimating && widget.progress > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: widget.size * 0.88,
                    height: widget.size * 0.88,
                    child: CircularProgressIndicator(
                      value: widget.isAnimating ? null : 0,
                      strokeWidth: widget.size * 0.035,
                      color: const Color(0xFF0078D4),
                      backgroundColor: const Color(0xFFEDEBE9),
                    ),
                  ),
                  if (widget.isAnimating)
                    Transform.rotate(
                      angle: _controller.value * 2 * math.pi,
                      child: SizedBox(
                        width: widget.size * 0.88,
                        height: widget.size * 0.88,
                        child: CircularProgressIndicator(
                          value: 0.22,
                          strokeWidth: widget.size * 0.035,
                          color: const Color(0xFF106EBE),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  Container(
                    width: widget.size * 0.58,
                    height: widget.size * 0.58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFEDEBE9)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AppLogo(
                        size: widget.size * 0.46,
                        showShadow: false,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (showProgress) ...[
          SizedBox(height: widget.size * 0.08),
          Text(
            '${(widget.progress * 100).round()}%',
            style: TextStyle(
              fontSize: widget.size * 0.09,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF323130),
            ),
          ),
        ],
      ],
    );
  }
}
