import 'package:flutter/material.dart';

class AppConstants {
  static const ColorScheme colorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: Color(0xFFfe640b),
    onPrimary: Color(0xFFeff1f5),
    primaryContainer: Color(0xFFfe640b),
    onPrimaryContainer: Color(0xFFeff1f5),
    secondary: Color(0xFF7c7f93),
    onSecondary: Color(0xFFeff1f5),
    secondaryContainer: Color(0xFFe6e9ef),
    onSecondaryContainer: Color(0xFF4c4f69),
    tertiary: Color(0xFFea76cb),
    onTertiary: Color(0xFFeff1f5),
    tertiaryContainer: Color(0xFFf4dbd6),
    onTertiaryContainer: Color(0xFF4c4f69),
    error: Color(0xFFd20f39),
    onError: Color(0xFFeff1f5),
    errorContainer: Color(0xFFfce4ec),
    onErrorContainer: Color(0xFF4c4f69),
    surface: Color(0xFFeff1f5),
    onSurface: Color(0xFF4c4f69),
    surfaceContainerHighest: Color(0xFFccd0da),
    onSurfaceVariant: Color(0xFF6c6f85),
    outline: Color(0xFF9ca0b0),
    outlineVariant: Color(0xFFbcc0cc),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF313244),
    onInverseSurface: Color(0xFFeff1f5),
    inversePrimary: Color(0xFFfe640b),
    surfaceTint: Color(0xFFfe640b),
  );

  static final defaultSettings = {
    "discussionTime": 480, // 8 minutes
    "votingTime": 120, // 2 minutes
    "startTimerOnGameStart": true,
  };
}
