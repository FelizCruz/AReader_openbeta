import 'dart:ui';
import 'eink_palette.dart';

enum EInkMode {
  disabled,
  standardLight,
  invertedNight,
}

/// Controller for toggling E-Ink rendering modes, color palettes, and ghosting mitigation.
class EInkThemeController {
  EInkMode _currentMode;

  EInkThemeController({EInkMode initialMode = EInkMode.disabled})
      : _currentMode = initialMode;

  EInkMode get currentMode => _currentMode;
  bool get isEInkActive => _currentMode != EInkMode.disabled;
  bool get isInvertedNight => _currentMode == EInkMode.invertedNight;

  void setMode(EInkMode mode) {
    _currentMode = mode;
  }

  void toggleInvertedNight() {
    if (_currentMode == EInkMode.invertedNight) {
      _currentMode = EInkMode.disabled;
    } else {
      _currentMode = EInkMode.invertedNight;
    }
  }

  /// Returns active background color.
  Color get backgroundColor {
    switch (_currentMode) {
      case EInkMode.invertedNight:
        return EInkPalette.invertedBackground;
      case EInkMode.standardLight:
        return EInkPalette.lightBackground;
      case EInkMode.disabled:
        return const Color(0xFF1E1E1E); // Default dark background
    }
  }

  /// Returns active text color.
  Color get textColor {
    switch (_currentMode) {
      case EInkMode.invertedNight:
        return EInkPalette.invertedForeground;
      case EInkMode.standardLight:
        return EInkPalette.lightForeground;
      case EInkMode.disabled:
        return const Color(0xFFF0F0F0);
    }
  }

  /// Returns animation duration (suppressed to 0ms when E-Ink is enabled to eliminate screen ghosting).
  Duration get animationDuration {
    if (isEInkActive) {
      return Duration.zero;
    }
    return const Duration(milliseconds: 250);
  }

  /// Flag indicating whether page turn transitions should be instant (zero ghosting).
  bool get suppressAnimations => isEInkActive;
}
