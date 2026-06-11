import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mole_ui/ui/widgets/app_logo.dart';

/// Animated launch splash with the Khine logo.
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({
    super.key,
    required this.onFinished,
    this.waitFor,
    this.minimumDuration = const Duration(seconds: 10),
  });

  final VoidCallback onFinished;
  final Future<void>? waitFor;
  final Duration minimumDuration;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final AnimationController _textController;
  late final AnimationController _exitController;

  static const _ringColors = [
    Color(0xFF5AC8FA),
    Color(0xFF007AFF),
    Color(0xFF5856D6),
    Color(0xFFAF52DE),
    Color(0xFF5AC8FA),
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _runSplash();
  }

  Future<void> _runSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    _entranceController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    _textController.forward();

    final waits = <Future<void>>[
      Future<void>.delayed(widget.minimumDuration),
    ];
    final gate = widget.waitFor;
    if (gate != null) waits.add(gate);

    await Future.wait(waits);
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;
    widget.onFinished();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exit = CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController,
        _pulseController,
        _ringController,
        _textController,
        _exitController,
      ]),
      builder: (context, _) {
        final entrance = Curves.easeOutBack.transform(_entranceController.value);
        final pulse = 0.97 + (_pulseController.value * 0.05);
        final logoScale = entrance * pulse;
        final logoOpacity = (1 - exit.value).clamp(0.0, 1.0);
        final textOpacity =
            (_textController.value * (1 - exit.value)).clamp(0.0, 1.0);
        final textSlide = (1 - _textController.value) * 18;

        return Opacity(
          opacity: (1 - exit.value).clamp(0.0, 1.0),
          child: Container(
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                _AmbientGlow(pulse: _pulseController.value),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: logoOpacity,
                        child: Transform.scale(
                          scale: logoScale,
                          child: SizedBox(
                            width: 300,
                            height: 300,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: _ringController.value * 2 * math.pi,
                                  child: CustomPaint(
                                    size: const Size(300, 300),
                                    painter: _SplashRingPainter(
                                      colors: _ringColors,
                                    ),
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 22,
                                      sigmaY: 22,
                                    ),
                                    child: Container(
                                      width: 220,
                                      height: 220,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.45,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF007AFF)
                                                .withValues(alpha: 0.2),
                                            blurRadius: 36,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: AppLogo(
                                          size: 196,
                                          showShadow: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: textOpacity,
                        child: Transform.translate(
                          offset: Offset(0, textSlide),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Khine',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'macOS system toolkit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                  color: Color(0xFF636366),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Opacity(
                        opacity: textOpacity * 0.85,
                        child: const _SplashDots(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = 0.92 + pulse * 0.12;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: size.height * 0.18,
            left: size.width * 0.12,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5AC8FA).withValues(alpha: 0.22),
                      const Color(0xFF5AC8FA).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.16,
            right: size.width * 0.1,
            child: Transform.scale(
              scale: 1.1 - pulse * 0.08,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5856D6).withValues(alpha: 0.16),
                      const Color(0xFF5856D6).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashRingPainter extends CustomPainter {
  const _SplashRingPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweep = SweepGradient(
      colors: colors,
      startAngle: 0,
      endAngle: 2 * math.pi,
    ).createShader(rect);

    final paint = Paint()
      ..shader = sweep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.2, 2 * math.pi * 0.72, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashRingPainter oldDelegate) => false;
}

class _SplashDots extends StatefulWidget {
  const _SplashDots();

  @override
  State<_SplashDots> createState() => _SplashDotsState();
}

class _SplashDotsState extends State<_SplashDots>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_controller.value + index * 0.2) % 1.0;
            final scale = 0.6 + (math.sin(phase * 2 * math.pi) + 1) * 0.2;
            final opacity = 0.35 + (math.sin(phase * 2 * math.pi) + 1) * 0.325;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
