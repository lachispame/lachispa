import 'package:flutter/material.dart';
import 'app_tokens.dart';

const AppTokens chispaTokens = AppTokens(
  backgroundGradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F1419),
      Color(0xFF1A1D47),
      Color(0xFF2D3FE7),
    ],
    stops: [0.0, 0.5, 1.0],
  ),
  surface: Color(0x0DFFFFFF),         // white @ 0.05
  outline: Color(0x1AFFFFFF),         // white @ 0.10
  outlineStrong: Color(0x2EFFFFFF),   // white @ 0.18
  textPrimary: Colors.white,
  textSecondary: Color(0x8CFFFFFF),   // white @ 0.55
  textTertiary: Color(0x73FFFFFF),    // white @ 0.45
  textAccent: Color(0xFF6B7FFF),
  accentGradient: LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2D3FE7), Color(0xFF4C63F7)],
  ),
  accentSolid: Color(0xFF4C63F7),
  accentBright: Color(0xFF5B73FF),
  accentForeground: Colors.white,
  statusHealthy: Color(0xFF4ADE80),
  statusUnhealthy: Color(0xFFEF4444),
  statusChecking: Color(0x40FFFFFF),  // white @ 0.25
  statusWarning: Color(0xFFFFA726),   // orange warning indicator
  ctaShadow: Color(0x59000000),       // black @ 0.35
  dialogBackground: Color(0xFF1A1D47),
  inputFill: Color(0x0DFFFFFF),       // white @ 0.05
);

ThemeData chispaTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1419),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4C63F7),
      onPrimary: Colors.white,
      secondary: Color(0xFF6B7FFF),
      onSecondary: Colors.white,
      surface: Color(0xFF1A1D47),
      onSurface: Colors.white,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    ),
    extensions: const [chispaTokens],
  );
}
