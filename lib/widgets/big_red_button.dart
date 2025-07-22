import 'package:flutter/material.dart';

class BigRedButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const BigRedButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 32.0,
    this.backgroundColor = const Color(0xFFE53E3E), // Red color
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final double shadowOffset = size * 0.08; // 8% of button size for 3D depth
    final double baseRadius = size * 0.65; // Larger gray base circle
    final double buttonRadius = size * 0.5; // Main button radius

    // Create darker color for bottom circle and cylinder sides
    final HSLColor hslColor = HSLColor.fromColor(backgroundColor);
    final Color darkerColor = hslColor
        .withLightness((hslColor.lightness * 0.6).clamp(0.0, 1.0))
        .toColor();

    return SizedBox(
      width: baseRadius * 2,
      height: baseRadius * 2 + shadowOffset,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gray base circle (bottom layer, largest)
          Positioned(
            bottom: 0,
            child: Container(
              width: baseRadius * 2,
              height: baseRadius * 2,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Bottom circle (darker color, translated down)
          Positioned(
            child: Container(
              width: buttonRadius * 2,
              height: buttonRadius * 2,
              decoration: BoxDecoration(
                color: darkerColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Cylinder side rectangle (between bottom and top circles)
          Positioned(
            child: Container(
              width: buttonRadius * 2,
              height: shadowOffset, // Slight overlap to avoid gaps
              decoration: BoxDecoration(
                color: darkerColor,
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
            ),
          ),

          // Top circle (main button)
          Positioned(
            top: 0,
            child: SizedBox(
              width: buttonRadius * 2,
              height: buttonRadius * 2,
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: iconColor,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(icon, color: iconColor, size: size * 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
