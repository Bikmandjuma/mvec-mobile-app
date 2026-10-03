import 'package:flutter/material.dart';

import '../theme.dart';

/// Storefront palette.
///
/// These are the same sky-blue design tokens the control center uses, re-exported
/// under the storefront names so both halves of the app can never drift apart.
/// Source of truth: [MvColors] in `core/theme.dart`.
class AppColors {
  AppColors._();

  /// `--blue` — the sky blue the app is built around.
  static const Color primary = MvColors.skyBlue;
  static const Color primaryDark = MvColors.primaryDark;
  static const Color primaryDeep = MvColors.primaryDeep;
  static const Color primaryLight = MvColors.accentLight;

  /// Brand gradient, same as `--gradient` in the web app:
  /// `#9ae2fb 0%, #55c9f2 45%, #25addb 100%`.
  static const List<Color> brandGradient = <Color>[
    MvColors.accentLight,
    MvColors.skyBlue,
    MvColors.primaryDark,
  ];

  /// The sky blue reserved for filled surfaces that must carry white text or a
  /// white glyph — active category chips, the floating cart action, the sliding
  /// indicator. `MvColors.skyBlue` (#55C9F2) is too light to hold white content
  /// at AA contrast, so those spots read this deeper step of the same hue
  /// instead. Never use it for hairline text on a light background.
  static const Color skyBlueSolid = Color(0xFF0EA5E9);

  /// Recessed fill for unselected chips and inactive pills (`--slate-100`).
  /// Deliberately neutral: only the *selected* chip is allowed to carry the
  /// sky-blue accent, so this must stay grey.
  static const Color chipNeutral = Color(0xFFF1F5F9);

  static const Color secondary = Color(0xFFF0A629); // star rating amber
  static const Color accent = Color(0xFF168D67); // price-drop green
  static const Color soft = MvColors.soft; // --soft

  static const Color background = MvColors.page; // --page
  static const Color surface = Colors.white; // --surface
  static const Color surfaceVariant = MvColors.surface2; // --surface-2
  static const Color textPrimary = MvColors.ink; // --text / --ink
  static const Color textSecondary = MvColors.muted; // --muted-text
  static const Color border = MvColors.border; // --border / --line

  static const Color error = MvColors.errorText; // status.danger
  static const Color warning = MvColors.warningText; // status.warning/pending
  static const Color success = MvColors.successText; // status.active
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle headline(BuildContext context) {
    final mv = context.mv;
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      color: mv.text,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    final mv = context.mv;
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: mv.text,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle title(BuildContext context) {
    final mv = context.mv;
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: mv.text,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle body(BuildContext context) {
    final mv = context.mv;
    return Theme.of(context).textTheme.bodyMedium!.copyWith(color: mv.text);
  }

  static TextStyle bodySecondary(BuildContext context) {
    final mv = context.mv;
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: mv.textMuted);
  }

  static TextStyle caption(BuildContext context) {
    final mv = context.mv;
    return Theme.of(context).textTheme.bodySmall!.copyWith(color: mv.textMuted);
  }

  static TextStyle price(BuildContext context) {
    final mv = context.mv;
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      color: mv.text,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle oldPrice(BuildContext context) {
    final mv = context.mv;
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: mv.textMuted,
      decoration: TextDecoration.lineThrough,
    );
  }
}

class AppTheme {
  AppTheme._();

  /// The storefront shares the control center theme so the whole app renders
  /// from one sky-blue palette.
  static ThemeData get light => buildAppTheme(Brightness.light);

  static ThemeData get dark => buildAppTheme(Brightness.dark);
}
