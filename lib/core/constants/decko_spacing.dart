/// Centralised spacing and shape tokens.
///
/// Keeping these in one place stops magic numbers drifting across widgets and
/// keeps Decko's rhythm consistent as screens are added.
abstract final class DeckoSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Comfortable horizontal page padding for mobile.
  static const double pagePadding = 20;
}

/// Corner radii used across cards, buttons and surfaces.
abstract final class DeckoRadii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double pill = 999;
}
