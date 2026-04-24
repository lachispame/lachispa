import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.backgroundGradient,
    required this.scaffoldBase,
    required this.surface,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textAccent,
    required this.accentGradient,
    required this.accentSolid,
    required this.accentBright,
    required this.accentForeground,
    required this.statusHealthy,
    required this.statusUnhealthy,
    required this.statusChecking,
    required this.statusWarning,
    required this.statusWarningSoft,
    required this.ctaShadow,
    required this.dialogBackground,
    required this.inputFill,
  });

  final Gradient backgroundGradient;
  final Color scaffoldBase;
  final Color surface;
  final Color outline;
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textAccent;
  final Gradient accentGradient;
  final Color accentSolid;
  final Color accentBright;
  final Color accentForeground;
  final Color statusHealthy;
  final Color statusUnhealthy;
  final Color statusChecking;
  final Color statusWarning;
  final Color statusWarningSoft;
  final Color ctaShadow;
  final Color dialogBackground;
  final Color inputFill;

  @override
  AppTokens copyWith({
    Gradient? backgroundGradient,
    Color? scaffoldBase,
    Color? surface,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textAccent,
    Gradient? accentGradient,
    Color? accentSolid,
    Color? accentBright,
    Color? accentForeground,
    Color? statusHealthy,
    Color? statusUnhealthy,
    Color? statusChecking,
    Color? statusWarning,
    Color? statusWarningSoft,
    Color? ctaShadow,
    Color? dialogBackground,
    Color? inputFill,
  }) {
    return AppTokens(
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      scaffoldBase: scaffoldBase ?? this.scaffoldBase,
      surface: surface ?? this.surface,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textAccent: textAccent ?? this.textAccent,
      accentGradient: accentGradient ?? this.accentGradient,
      accentSolid: accentSolid ?? this.accentSolid,
      accentBright: accentBright ?? this.accentBright,
      accentForeground: accentForeground ?? this.accentForeground,
      statusHealthy: statusHealthy ?? this.statusHealthy,
      statusUnhealthy: statusUnhealthy ?? this.statusUnhealthy,
      statusChecking: statusChecking ?? this.statusChecking,
      statusWarning: statusWarning ?? this.statusWarning,
      statusWarningSoft: statusWarningSoft ?? this.statusWarningSoft,
      ctaShadow: ctaShadow ?? this.ctaShadow,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      inputFill: inputFill ?? this.inputFill,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      backgroundGradient:
          t < 0.5 ? backgroundGradient : other.backgroundGradient,
      scaffoldBase: Color.lerp(scaffoldBase, other.scaffoldBase, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      accentGradient: t < 0.5 ? accentGradient : other.accentGradient,
      accentSolid: Color.lerp(accentSolid, other.accentSolid, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t)!,
      statusHealthy: Color.lerp(statusHealthy, other.statusHealthy, t)!,
      statusUnhealthy:
          Color.lerp(statusUnhealthy, other.statusUnhealthy, t)!,
      statusChecking: Color.lerp(statusChecking, other.statusChecking, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusWarningSoft:
          Color.lerp(statusWarningSoft, other.statusWarningSoft, t)!,
      ctaShadow: Color.lerp(ctaShadow, other.ctaShadow, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
