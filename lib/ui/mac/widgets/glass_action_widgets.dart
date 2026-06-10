import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared macOS-style frosted glass surface (liquid glass material).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.padding,
    this.blurSigma = 20,
    this.tintOpacity = 0.55,
    this.borderOpacity = 0.65,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double tintOpacity;
  final double borderOpacity;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: tintOpacity + 0.12),
                Colors.white.withValues(alpha: tintOpacity),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Cross-fade + lift + blur dissolve used when switching main tabs.
class GlassTabTransition extends StatelessWidget {
  const GlassTabTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        final blur = (1 - t) * 14;
        final scale = lerpDouble(0.985, 1, t)!;

        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 10),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// AnimatedSwitcher wrapper with the glass tab transition preset.
class GlassTabSwitcher extends StatelessWidget {
  const GlassTabSwitcher({
    super.key,
    required this.tabKey,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
  });

  final Object tabKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final child in previousChildren)
              Positioned.fill(child: child),
            if (currentChild != null) Positioned.fill(child: currentChild),
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return GlassTabTransition(animation: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey(tabKey),
        child: child,
      ),
    );
  }
}

class GlassProgressSection extends StatelessWidget {
  const GlassProgressSection({
    super.key,
    required this.progress,
    required this.percent,
  });

  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      width: 340,
      blurSigma: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF5AC8FA),
                                Color(0xFF007AFF),
                                Color(0xFF5856D6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$percent% complete',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
    );
  }
}

class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5AC8FA), Color(0xFF007AFF), Color(0xFF5856D6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassActionErrorText extends StatelessWidget {
  const GlassActionErrorText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: const Color(0xFFFF3B30).withValues(alpha: 0.85),
      ),
    );
  }
}

class GlassActionSuccessText extends StatelessWidget {
  const GlassActionSuccessText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: const Color(0xFF34C759).withValues(alpha: 0.9),
      ),
    );
  }
}
