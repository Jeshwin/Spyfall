import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StickyNote extends StatelessWidget {
  final String text;

  // Private styling constants
  static const double _width = 200;
  static const double _height = 200;
  static const Color _noteColor = Color(0xFFFFFAC2); // Light yellow
  static const Color _shadowColor = Color(0xFF8C8A73); // Darker shadow color
  static const double _rotation = 10; // degrees
  static final TextStyle _textStyle = GoogleFonts.getFont(
    'Delicious Handrawn',
    textStyle: TextStyle(
      fontSize: 24,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
  );

  const StickyNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        children: [
          // Sticky note
          Positioned(
            left: 0,
            top: 0,
            child: Transform.rotate(
              angle: _rotation * math.pi / 180,
              child: Container(
                width: _width,
                height: _height,
                decoration: BoxDecoration(
                  color: _noteColor,
                  boxShadow: [
                    BoxShadow(
                      color: _shadowColor,
                      blurRadius: 4,
                      offset: const Offset(8, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: _textStyle,
                    ),
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
