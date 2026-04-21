import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DS {
  const DS._();

  // ── Spacing scale ──
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;

  /// Standard horizontal page padding.
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: s16);

  // ── Radius scale ──
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  // ── Animation durations ──
  static const Duration aniFast = Duration(milliseconds: 150);
  static const Duration aniNormal = Duration(milliseconds: 250);
  static const Duration aniSlow = Duration(milliseconds: 400);

  // ── Shadow ──
  static final List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 20,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Typography helpers ──
  static TextStyle heading(double size) => GoogleFonts.notoSerifTc(
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: const Color(0xFF151514),
  );

  static TextStyle body(double size) => GoogleFonts.notoSansTc(
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF777972),
  );
}


