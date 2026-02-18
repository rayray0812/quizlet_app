import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final String _appFontFamily = GoogleFonts.notoSansTc().fontFamily!;
  // Stitch-aligned palette
  static const indigo = Color(0xFF8F9876); // primary sage
  static const cyan = Color(0xFFA4B5BC); // morandi blue
  static const orange = Color(0xFFA7B388); // soft sage accent
  static const red = Color(0xFFB47575); // muted error
  static const gold = Color(0xFFD9D2C5); // morandi sand
  static const green = Color(0xFF7C8762); // deep sage
  static const purple = Color(0xFFC7ADA5); // morandi rose

  // Breakdown colors
  static const breakdownNew = Color(0xFFD3D9C3);
  static const breakdownLearning = Color(0xFFD9D2C5);
  static const breakdownReview = Color(0xFFA7B388);

  static const _bgLight = Color(0xFFFDFBF7);
  static const _textMain = Color(0xFF151514);
  static const _textSubtle = Color(0xFF777972);
  static const _borderSoft = Color(0xFFE5E1D8);

  /// Shared card decoration matching stitch style.
  static BoxDecoration softCardDecoration({
    Color? fillColor,
    double borderRadius = 14,
    Color? borderColor,
    double elevation = 1,
  }) {
    return BoxDecoration(
      color: fillColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? _borderSoft, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03 * elevation),
          blurRadius: 20 * elevation,
          offset: Offset(0, 2 * elevation),
        ),
      ],
    );
  }

  static final ThemeData lightTheme = _buildLightTheme();
  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final baseText = GoogleFonts.notoSansTcTextTheme();
    final scheme = ColorScheme.fromSeed(
      seedColor: indigo,
      brightness: Brightness.light,
    ).copyWith(
      primary: indigo,
      secondary: cyan,
      tertiary: purple,
      surface: _bgLight,
      surfaceContainerLowest: const Color(0xFFF7F7F3),
      surfaceContainerHigh: const Color(0xFFF2F1EC),
      onSurface: _textMain,
      outline: _textSubtle,
      outlineVariant: _borderSoft,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _appFontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bgLight,
      textTheme: baseText.copyWith(
        headlineLarge: GoogleFonts.notoSerifTc(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.35,
          color: _textMain,
        ),
        headlineMedium: GoogleFonts.notoSerifTc(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.35,
          color: _textMain,
        ),
        headlineSmall: GoogleFonts.notoSerifTc(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.35,
          color: _textMain,
        ),
        titleLarge: GoogleFonts.notoSerifTc(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.35,
          color: _textMain,
        ),
        titleMedium: GoogleFonts.notoSerifTc(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          height: 1.35,
          color: _textMain,
        ),
        bodyLarge: GoogleFonts.notoSansTc(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.55,
          color: _textMain,
        ),
        bodyMedium: GoogleFonts.notoSansTc(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.55,
          color: _textSubtle,
        ),
        labelLarge: GoogleFonts.notoSansTc(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: _textMain,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: _bgLight.withValues(alpha: 0.88),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textMain),
        titleTextStyle: GoogleFonts.notoSerifTc(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: _textMain,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSansTc(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: indigo.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.notoSansTc(
          fontWeight: FontWeight.w500,
          color: _textSubtle.withValues(alpha: 0.7),
        ),
        labelStyle: GoogleFonts.notoSansTc(
          fontWeight: FontWeight.w600,
          color: _textSubtle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: indigo.withValues(alpha: 0.9), width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: _borderSoft),
        labelStyle: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 4,
        selectedItemColor: indigo,
        unselectedItemColor: _textSubtle.withValues(alpha: 0.7),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.notoSansTc(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansTc(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        shadowColor: Colors.black.withValues(alpha: 0.05),
        indicatorColor: indigo.withValues(alpha: 0.10),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: indigo);
          }
          return IconThemeData(color: _textSubtle.withValues(alpha: 0.85));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.notoSansTc(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? indigo
                : _textSubtle,
          );
        }),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final baseText = GoogleFonts.notoSansTcTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: indigo,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: _appFontFamily,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: GoogleFonts.notoSerifTc(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: scheme.onSurface,
        ),
      ),
    );
  }

}

/// Paper-like grain noise overlay for artsy texture.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainTexturePainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _GrainTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = const Color(0x06000000);
    final count = (size.width * size.height / 120).clamp(0, 8000).toInt();
    for (var i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
