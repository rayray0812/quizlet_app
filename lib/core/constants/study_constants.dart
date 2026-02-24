import 'package:flutter/animation.dart';

/// Centralised animation timings and curves for all study modes.
abstract final class StudyConstants {
  // -- Durations --
  static const Duration flipDuration = Duration(milliseconds: 480);
  static const Duration swipeOutDuration = Duration(milliseconds: 280);
  static const Duration tileMatchDuration = Duration(milliseconds: 340);
  static const Duration celebrationDuration = Duration(milliseconds: 920);
  static const Duration progressBarDuration = Duration(milliseconds: 360);
  static const Duration cardTransitionDuration = Duration(milliseconds: 200);
  static const Duration pageTransitionDuration = Duration(milliseconds: 320);

  // -- Curves --
  static const Curve flipCurve = Curves.easeInOutCubic;
  static const Curve swipeOutCurve = Curves.easeOutCubic;
  static const Curve tileMatchCurve = Curves.easeOutBack;
  static const Curve progressBarCurve = Curves.easeOutCubic;
  static const Curve pageTransitionCurve = Curves.easeOutCubic;
}
