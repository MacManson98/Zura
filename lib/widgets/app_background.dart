import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showFloatingElements;
  final bool useImageBackground;

  const AppBackground({
    super.key,
    required this.child,
    this.showFloatingElements = true,
    this.useImageBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Use your background image
        image: useImageBackground 
            ? const DecorationImage(
                image: AssetImage('assets/images/app_background.png'),
                fit: BoxFit.cover,
              )
            : null,
        // Fallback gradient if image fails to load or is disabled
        gradient: !useImageBackground 
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF121212),
                  Color(0xFF0A0A0A),
                ],
              )
            : null,
      ),
      child: Stack(
        children: [
          // Optional: Add a subtle overlay to ensure text readability
          if (useImageBackground)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          
          // Your main content
          child,
        ],
      ),
    );
  }
}