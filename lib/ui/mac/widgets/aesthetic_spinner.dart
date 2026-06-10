import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AestheticSpinner extends StatefulWidget {
  const AestheticSpinner({
    super.key,
    required this.isAnimating,
    this.progress = 0,
    this.size = 200,
  });

  final bool isAnimating;
  final double progress;
  final double size;

  @override
  State<AestheticSpinner> createState() => _AestheticSpinnerState();
}

class _AestheticSpinnerState extends State<AestheticSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;

  static const _gradientColors = [
    Color(0xFF5AC8FA),
    Color(0xFF007AFF),
    Color(0xFF5856D6),
    Color(0xFFAF52DE),
    Color(0xFF5AC8FA),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AestheticSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating != widget.isAnimating) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isAnimating) {
      _spinController.repeat();
    } else {
      _spinController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinController, _pulseController]),
      builder: (context, _) {
        final pulse = 0.92 + (_pulseController.value * 0.08);
        final glowOpacity = widget.isAnimating ? 0.35 : 0.18;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: widget.isAnimating ? 1.0 : pulse,
                child: Container(
                  width: widget.size * 0.92,
                  height: widget.size * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withValues(alpha: glowOpacity),
                        blurRadius: 48,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFFAF52DE).withValues(alpha: glowOpacity * 0.6),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: _spinController.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size.square(widget.size * 0.82),
                  painter: _SpinnerArcPainter(
                    colors: _gradientColors,
                    strokeWidth: widget.size * 0.045,
                    arcSweep: widget.isAnimating ? 2.4 : 1.6,
                    opacity: widget.isAnimating ? 1.0 : 0.55,
                  ),
                ),
              ),
              Transform.rotate(
                angle: -_spinController.value * 2 * math.pi * 0.7,
                child: CustomPaint(
                  size: Size.square(widget.size * 0.62),
                  painter: _SpinnerArcPainter(
                    colors: _gradientColors.reversed.toList(),
                    strokeWidth: widget.size * 0.032,
                    arcSweep: widget.isAnimating ? 1.8 : 1.2,
                    opacity: widget.isAnimating ? 0.75 : 0.35,
                    startOffset: math.pi / 3,
                  ),
                ),
              ),
              _GlassCore(
                size: widget.size * 0.48,
                isAnimating: widget.isAnimating,
                progress: widget.progress,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassCore extends StatelessWidget {
  const _GlassCore({
    required this.size,
    required this.isAnimating,
    required this.progress,
  });

  final double size;
  final bool isAnimating;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.75),
                Colors.white.withValues(alpha: 0.35),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isAnimating
                ? Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: Color(0xFF1C1C1E),
                    ),
                  )
                : Icon(
                    Icons.auto_awesome_rounded,
                    size: size * 0.32,
                    color: const Color(0xFF007AFF).withValues(alpha: 0.85),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SpinnerArcPainter extends CustomPainter {
  _SpinnerArcPainter({
    required this.colors,
    required this.strokeWidth,
    required this.arcSweep,
    required this.opacity,
    this.startOffset = -math.pi / 2,
  });

  final List<Color> colors;
  final double strokeWidth;
  final double arcSweep;
  final double opacity;
  final double startOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: colors.map((c) => c.withValues(alpha: opacity)).toList(),
        transform: GradientRotation(startOffset),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startOffset, arcSweep, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerArcPainter oldDelegate) {
    return oldDelegate.arcSweep != arcSweep ||
        oldDelegate.opacity != opacity ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
