import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';

/// Route transition using shared-axis horizontal motion: the incoming page
/// fades in while shifting slightly, direction encodes navigation depth.
class TermoraSharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const TermoraSharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      child: child,
    );
  }
}

TextTheme _textTheme(Color primary) {
  return Typography.material2021().black
      .apply(bodyColor: primary, displayColor: primary)
      .copyWith(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: primary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: primary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: primary,
        ),
        bodySmall: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: primary,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: primary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: primary,
        ),
      );
}

ThemeData termoraTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final bg = dark ? AppColors.darkBg : AppColors.lightBg;
  final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
  final surfaceHigh =
      dark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;
  final surfaceHighest =
      dark ? AppColors.darkSurfaceHighest : AppColors.lightSurfaceHighest;
  final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
  final textPrimary =
      dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  final textSecondary =
      dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  final textTertiary =
      dark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  final scrim = dark ? AppColors.darkScrim : AppColors.lightScrim;
  final hoverOverlay =
      dark ? AppColors.darkHoverOverlay : AppColors.lightHoverOverlay;
  final pressedOverlay =
      dark ? AppColors.darkPressedOverlay : AppColors.lightPressedOverlay;
  final surfaceSunken =
      dark ? AppColors.darkSurface : AppColors.lightSurfaceSunken;

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
    surfaceContainerLowest: bg,
    surfaceContainerLow: bg,
    surfaceContainer: surface,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHighest,
    onSurfaceVariant: textSecondary,
    outline: border,
    outlineVariant: border,
    shadow: Colors.black,
    scrim: scrim,
    inverseSurface: textPrimary,
    onInverseSurface: bg,
    inversePrimary: AppColors.accent,
  );

  RoundedRectangleBorder radius(double r, {Color? side}) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r),
        side: side == null ? BorderSide.none : BorderSide(color: side),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme,
    hoverColor: hoverOverlay,
    splashColor: AppColors.accentSoft,
    highlightColor: pressedOverlay,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    dividerTheme: DividerThemeData(thickness: 1, color: border, space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: TermoraSharedAxisPageTransitionsBuilder(),
        TargetPlatform.linux: TermoraSharedAxisPageTransitionsBuilder(),
        TargetPlatform.windows: TermoraSharedAxisPageTransitionsBuilder(),
        TargetPlatform.macOS: TermoraSharedAxisPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      foregroundColor: textPrimary,
      titleTextStyle: textTheme.titleMedium,
      iconTheme: IconThemeData(color: textPrimary, size: 20),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Space.x5, vertical: Space.x2),
        ),
        shape: WidgetStatePropertyAll(radius(Radii.md)),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        animationDuration: Motion.hover,
        elevation: const WidgetStatePropertyAll(0),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.accent.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.accentHover;
          }
          return AppColors.accent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Colors.white.withValues(alpha: 0.6);
          }
          return Colors.white;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.accentHover;
          }
          return AppColors.accent;
        }),
        overlayColor: const WidgetStatePropertyAll(AppColors.accentSoft),
        shape: WidgetStatePropertyAll(radius(Radii.md)),
        animationDuration: Motion.hover,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: border)),
        foregroundColor: WidgetStatePropertyAll(textPrimary),
        overlayColor: WidgetStatePropertyAll(hoverOverlay),
        shape: WidgetStatePropertyAll(radius(Radii.md)),
        animationDuration: Motion.hover,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        shape: WidgetStatePropertyAll(radius(Radii.md)),
        iconSize: const WidgetStatePropertyAll(20),
        animationDuration: Motion.hover,
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return textPrimary;
          }
          return textSecondary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return pressedOverlay;
          if (states.contains(WidgetState.hovered)) return hoverOverlay;
          return Colors.transparent;
        }),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        animationDuration: Motion.control,
        side: WidgetStatePropertyAll(BorderSide(color: border)),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentSoft;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return textSecondary;
        }),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceSunken,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x3,
      ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      hintStyle: TextStyle(color: textTertiary),
      labelStyle: textTheme.labelMedium,
      errorStyle: textTheme.labelSmall?.copyWith(color: AppColors.danger),
      prefixIconColor: textTertiary,
      suffixIconColor: textTertiary,
      iconColor: textTertiary,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return dark ? const Color(0xFF2A2D33) : const Color(0xFFD3D7DD);
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return dark ? const Color(0xFF8F959F) : Colors.white;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackOutlineWidth: const WidgetStatePropertyAll(0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    checkboxTheme: const CheckboxThemeData(
      fillColor: WidgetStatePropertyAll(AppColors.accent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(AppColors.accent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor:
          dark ? const Color(0xFF2A2D33) : const Color(0xFFDDE1E7),
      thumbColor: Colors.white,
      overlayColor: AppColors.accentSoft,
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearMinHeight: 2,
      linearTrackColor: Colors.transparent,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll(false),
      trackVisibility: const WidgetStatePropertyAll(false),
      interactive: true,
      thickness: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered) ? 4.0 : 2.0,
      ),
      radius: const Radius.circular(2),
      thumbColor: WidgetStatePropertyAll(
        dark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.22),
      ),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceHighest : const Color(0xFF1E2126),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      textStyle: textTheme.labelSmall?.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: Space.x2, vertical: 6),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? AppColors.darkSurfaceHighest : AppColors.lightSurfaceHigh,
      shape: radius(Radii.lg, side: border),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      position: PopupMenuPosition.under,
      menuPadding: const EdgeInsets.all(Space.x1),
      textStyle: textTheme.labelLarge,
      iconColor: textSecondary,
    ),
    dialogTheme: DialogThemeData(
      shape: radius(Radii.xl),
      backgroundColor: surfaceHigh,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
      barrierColor: scrim,
      actionsPadding: const EdgeInsets.fromLTRB(
        Space.x4,
        0,
        Space.x3,
        Space.x3,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceHigh,
      modalBackgroundColor: surfaceHigh,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: textTertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      constraints: const BoxConstraints(maxWidth: 560),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: radius(Radii.lg),
      backgroundColor: surfaceHigh,
      elevation: 2,
      insetPadding: const EdgeInsets.all(Space.x4),
      showCloseIcon: true,
      closeIconColor: textTertiary,
      actionTextColor: AppColors.accent,
      contentTextStyle: textTheme.labelLarge,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.x4),
      minVerticalPadding: Space.x3,
      titleTextStyle: textTheme.labelLarge,
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
      iconColor: textSecondary,
      selectedColor: AppColors.accent,
      selectedTileColor: AppColors.accentSoft,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: radius(Radii.lg, side: border),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accentSoft,
      selectionHandleColor: AppColors.accent,
    ),
  );
}
