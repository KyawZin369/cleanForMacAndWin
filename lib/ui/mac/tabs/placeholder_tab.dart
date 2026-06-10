import 'package:flutter/material.dart';

class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.black.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
