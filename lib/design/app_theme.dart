import 'package:flutter/material.dart';

import 'tokens.dart';

/// A page transition that fades the new route in while sliding it up slightly.
class _FadeUpwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeUpwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

TextTheme _textTheme(Color primary) {
  return Typography.material2021().black.apply(
    bodyColor: primary,
    displayColor: primary,
  ).copyWith(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: primary),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: primary),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: primary),
    labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primary),
  );
}

ThemeData termoraTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final bg = dark ? AppColors.darkBg : AppColors.lightBg;
  final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
  final surfaceHigh = dark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;
  final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
  final textPrimary = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  final onSurfaceVariant = dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  final textTheme = _textTheme(textPrimary);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: textPrimary,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.accentSoft,
    onSecondaryContainer: textPrimary,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: textPrimary,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: surfaceHigh,
    onSurfaceVariant: onSurfaceVariant,
    outline: border,
    outlineVariant: border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: textPrimary,
    onInverseSurface: bg,
    inversePrimary: AppColors.accent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: _FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: _FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: _FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleMedium,
      iconTheme: IconThemeData(color: textPrimary, size: 20),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      hintStyle: TextStyle(color: dark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: Space.x4),
      minVerticalPadding: Space.x3,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
      backgroundColor: surfaceHigh,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      backgroundColor: surfaceHigh,
      contentTextStyle: textTheme.bodyMedium,
    ),
    dividerTheme: DividerThemeData(thickness: 1, color: border, space: 1),
  );
}
