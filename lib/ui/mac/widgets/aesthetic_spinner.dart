import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mole_ui/ui/widgets/app_logo.dart';

class AestheticSpinner extends StatefulWidget {
  const AestheticSpinner({
    super.key,
    required this.isAnimating,
    this.progress = 0,
    this.size = 280,
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
  late final Animation<double> _spinAnimation;
  late final Animation<double> _pulseAnimation;

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
      duration: const Duration(milliseconds: 3200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.linear,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );

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
      if (!_spinController.isAnimating) {
        _spinController.repeat();
      }
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _spinController
        ..stop()
        ..reset();
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
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
      animation: Listenable.merge([_spinAnimation, _pulseAnimation]),
      builder: (context, _) {
        final spin = _spinAnimation.value;
        final pulse = 0.96 + (_pulseAnimation.value * 0.04);
        final glowOpacity = widget.isAnimating ? 0.32 : 0.16;
        final coreScale = widget.isAnimating ? (0.985 + _pulseAnimation.value * 0.03) : pulse;
        final showProgressLabel = widget.isAnimating && widget.progress > 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
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
                  CustomPaint(
                    size: Size.square(widget.size * 0.86),
                    painter: _SpinnerTrackPainter(
                      strokeWidth: widget.size * 0.028,
                    ),
                  ),
                  Transform.rotate(
                    angle: spin * 2 * math.pi,
                    child: CustomPaint(
                      size: Size.square(widget.size * 0.86),
                      painter: _SpinnerArcPainter(
                        colors: _gradientColors,
                        strokeWidth: widget.size * 0.042,
                        arcSweep: widget.isAnimating ? 2.8 : 1.8,
                        opacity: widget.isAnimating ? 1.0 : 0.5,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -spin * 2 * math.pi * 0.55,
                    child: CustomPaint(
                      size: Size.square(widget.size * 0.68),
                      painter: _SpinnerArcPainter(
                        colors: _gradientColors.reversed.toList(),
                        strokeWidth: widget.size * 0.03,
                        arcSweep: widget.isAnimating ? 2.2 : 1.4,
                        opacity: widget.isAnimating ? 0.7 : 0.32,
                        startOffset: math.pi / 4,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: coreScale,
                    child: _GlassCore(size: widget.size * 0.62),
                  ),
                ],
              ),
            ),
            if (showProgressLabel) ...[
              SizedBox(height: widget.size * 0.08),
              Text(
                '${(widget.progress * 100).round()}%',
                style: TextStyle(
                  fontSize: widget.size * 0.11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GlassCore extends StatelessWidget {
  const _GlassCore({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.78),
                Colors.white.withValues(alpha: 0.38),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
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
            child: AppLogo(
              size: size * 0.82,
              showShadow: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinnerTrackPainter extends CustomPainter {
  _SpinnerTrackPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerTrackPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
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
