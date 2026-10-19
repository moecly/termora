import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'motion.dart';
import 'palette.dart';
import 'tokens.dart';

/// Depth-advance page transition: the incoming page fades in and settles from a
/// slightly scaled/offset state, while the outgoing page (secondary) slides out.
/// Under reduced motion the child is returned unchanged.
class TermoraPageTransition extends StatelessWidget {
  const TermoraPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final t = Motion.emphasized.transform(animation.value.clamp(0.0, 1.0));
        final s =
            Motion.emphasized.transform(secondaryAnimation.value.clamp(0.0, 1.0));
        return Transform.scale(
          scale: 1 + 0.012 * (1 - t),
          child: Transform.translate(
            offset: Offset(-28 * s, 18 * (1 - t)),
            child: Opacity(
              opacity: (t * (1 - 0.15 * s)).clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class TermoraPageTransitionsBuilder extends PageTransitionsBuilder {
  const TermoraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    return TermoraPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

TextTheme _textTheme(Color primary) {
  return Typography.material2021().black
      .apply(bodyColor: primary, displayColor: primary)
      .copyWith(
        headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
          color: primary,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
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
          letterSpacing: 0.6,
          color: primary,
        ),
      );
}

ThemeData termoraTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final textTheme = _textTheme(p.textPrimary);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.accentSoft,
    onPrimaryContainer: p.textPrimary,
    secondary: p.accent,
    onSecondary: p.onAccent,
    secondaryContainer: p.accentSoft,
    onSecondaryContainer: p.textPrimary,
    error: p.danger,
    onError: Colors.white,
    errorContainer: p.dangerSoft,
    onErrorContainer: p.textPrimary,
    surface: p.surface,
    onSurface: p.textPrimary,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.bg,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceHigh,
    surfaceContainerHighest: p.surfaceHighest,
    onSurfaceVariant: p.textSecondary,
    outline: p.border,
    outlineVariant: p.border,
    shadow: Colors.black,
    scrim: p.scrim,
    inverseSurface: p.textPrimary,
    onInverseSurface: p.bg,
    inversePrimary: p.accent,
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
    scaffoldBackgroundColor: p.bg,
    textTheme: textTheme,
    extensions: [p],
    hoverColor: p.hoverOverlay,
    splashColor: p.accentSoft,
    highlightColor: p.pressedOverlay,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    dividerTheme: DividerThemeData(thickness: 1, color: p.border, space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: TermoraPageTransitionsBuilder(),
        TargetPlatform.linux: TermoraPageTransitionsBuilder(),
        TargetPlatform.windows: TermoraPageTransitionsBuilder(),
        TargetPlatform.macOS: TermoraPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      foregroundColor: p.textPrimary,
      titleTextStyle: textTheme.titleMedium,
      iconTheme: IconThemeData(color: p.textPrimary, size: 20),
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
            return p.accent.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.pressed)) {
            return p.accentPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return p.accentHover;
          }
          return p.accent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.onAccent.withValues(alpha: 0.6);
          }
          return p.onAccent;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return p.accentPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return p.accentHover;
          }
          return p.accent;
        }),
        overlayColor: WidgetStatePropertyAll(p.accentSoft),
        shape: WidgetStatePropertyAll(radius(Radii.md)),
        animationDuration: Motion.hover,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        foregroundColor: WidgetStatePropertyAll(p.textPrimary),
        overlayColor: WidgetStatePropertyAll(p.hoverOverlay),
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
            return p.textPrimary;
          }
          return p.textSecondary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return p.pressedOverlay;
          if (states.contains(WidgetState.hovered)) return p.hoverOverlay;
          return Colors.transparent;
        }),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        animationDuration: Motion.control,
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.accentSoft;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.accent;
          }
          return p.textSecondary;
        }),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceSunken,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: p.danger, width: 1.5),
      ),
      hintStyle: TextStyle(color: p.textTertiary),
      labelStyle: textTheme.labelMedium,
      errorStyle: textTheme.labelSmall?.copyWith(color: p.danger),
      prefixIconColor: p.textTertiary,
      suffixIconColor: p.textTertiary,
      iconColor: p.textTertiary,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.accent;
        return p.borderStrong;
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.onAccent;
        return p.surface;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackOutlineWidth: const WidgetStatePropertyAll(0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStatePropertyAll(p.accent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStatePropertyAll(p.accent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      inactiveTrackColor: p.borderStrong,
      thumbColor: p.surface,
      overlayColor: p.accentSoft,
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
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
        brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.22),
      ),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: p.surfaceHighest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      textStyle: textTheme.labelSmall?.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: Space.x2, vertical: 6),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surfaceHighest,
      shape: radius(Radii.lg, side: p.border),
      elevation: 0,
      position: PopupMenuPosition.under,
      menuPadding: const EdgeInsets.all(Space.x1),
      textStyle: textTheme.labelLarge,
      iconColor: p.textSecondary,
    ),
    dialogTheme: DialogThemeData(
      shape: radius(Radii.xl),
      backgroundColor: p.surfaceHigh,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
      barrierColor: p.scrim,
      actionsPadding: const EdgeInsets.fromLTRB(
        Space.x4,
        0,
        Space.x3,
        Space.x3,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceHigh,
      modalBackgroundColor: p.surfaceHigh,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: p.textTertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      constraints: const BoxConstraints(maxWidth: 560),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: radius(Radii.lg),
      backgroundColor: p.surfaceHigh,
      elevation: 2,
      insetPadding: const EdgeInsets.all(Space.x4),
      showCloseIcon: true,
      closeIconColor: p.textTertiary,
      actionTextColor: p.accent,
      contentTextStyle: textTheme.labelLarge,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.x4),
      minVerticalPadding: Space.x3,
      titleTextStyle: textTheme.labelLarge,
      subtitleTextStyle: textTheme.bodySmall?.copyWith(color: p.textSecondary),
      iconColor: p.textSecondary,
      selectedColor: p.accent,
      selectedTileColor: p.accentSoft,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: radius(Radii.lg, side: p.border),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accentSoft,
      selectionHandleColor: p.accent,
    ),
  );
}
