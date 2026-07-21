import 'dart:ui';

/// High contrast color palette definitions for E-Ink displays and inverted night reading mode.
class EInkPalette {
  // Inverted E-Ink (Pure Dark / High Contrast Night Mode)
  static const Color invertedBackground = Color(0xFF000000);
  static const Color invertedForeground = Color(0xFFFFFFFF);
  static const Color invertedSubtext = Color(0xFFE0E0E0);
  static const Color invertedBorder = Color(0xFF444444);
  static const Color invertedAccent = Color(0xFFFFFFFF);

  // Standard Light E-Ink (Pure Light / Crisp Paper Mode)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF000000);
  static const Color lightSubtext = Color(0xFF333333);
  static const Color lightBorder = Color(0xFFCCCCCC);
  static const Color lightAccent = Color(0xFF000000);
}
