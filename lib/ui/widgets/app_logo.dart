import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Circular Khine app logo rendered from SVG.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 32,
    this.showShadow = true,
  });

  final double size;
  final bool showShadow;

  static const _assetPath = 'asset/image/app_logo.svg';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.22),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.07),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          _assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
