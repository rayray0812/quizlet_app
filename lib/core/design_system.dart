import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DS {
  const DS._();

  // Stitch-inspired palette
  static const Color primary = Color(0xFF8F9876);
  static const Color bgLight = Color(0xFFFDFBF7);
  static const Color bgDark = Color(0xFF1A1A18);
  static const Color text1 = Color(0xFF151514);
  static const Color text2 = Color(0xFF777972);
  static const Color border = Color(0xFFE5E1D8);

  // Radius
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  // Shadow
  static final List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 20,
      offset: const Offset(0, 2),
    ),
  ];

  // Typography
  static TextStyle heading(double size) => GoogleFonts.notoSerifTc(
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: text1,
  );

  static TextStyle body(double size) => GoogleFonts.notoSansTc(
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: text2,
  );
}


