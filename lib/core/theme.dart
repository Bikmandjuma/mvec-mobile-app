import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Design tokens lifted from MVEC frontend `src/styles.css`.
class MvColors {
  MvColors._();

  /// The app-wide sky-blue accent. Every active state, primary button, badge
  /// and selected tab resolves back to this one token, so the accent can never
  /// drift between screens. (Matches `--blue` in the web app's `src/styles.css`.)
  static const skyBlue = Color(0xFF55C9F2);

  /// Alias kept for the dozens of call sites that read the accent as `primary`.
  static const primary = skyBlue;
  static const primaryDark = Color(0xFF25ADDB);
  static const primaryDeep = Color(0xFF168DB8);
  static const accentLight = Color(0xFF9AE2FB);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, primary, primaryDark],
  );

  static const ink = Color(0xFF16252D);
  static const muted = Color(0xFF71808A);
  static const border = Color(0xFFE4EDF1);
  static const soft = Color(0xFFEEFAFF);
  static const page = Color(0xFFF7FBFD);
  static const surface2 = Color(0xFFF7FAFB);
  static const tableHeaderBg = Color(0xFFEEFAFF);
  static const rowHover = Color(0x0A25ADDB); // rgba(37,173,219,.035~0.04)

  static const successBg = Color(0xFFEAFAF4);
  static const successText = Color(0xFF15815E);
  static const successText2 = Color(0xFF16845B);
  static const warningBg = Color(0xFFFFF6E7);
  static const warningText = Color(0xFFB56A00);
  static const errorBg = Color(0xFFFFF0F0);
  static const errorText = Color(0xFFB42318);
  static const dangerBtn = Color(0xFFD94B4B);
  static const dangerIcon = Color(0xFFC63E3E);
  static const badgeRed = Color(0xFFE53935);
  static const neutralBg = Color(0xFFF2F5F6);
  static const neutralText = Color(0xFF66767D);
  static const infoBoxBg = Color(0xFFEFFAFF);
  static const infoBoxBorder = Color(0xFFC8EDF8);
  static const infoBoxText = Color(0xFF49646E);
  static const metricIconBg = Color(0xFFEAF9FD);

  // Dark theme
  static const darkPage = Color(0xFF0B151B);
  static const darkSurface = Color(0xFF13232C);
  static const darkSurface2 = Color(0xFF1A303B);
  static const darkSoft = Color(0xFF142C38);
  static const darkText = Color(0xFFEDF8FB);
  static const darkMuted = Color(0xFFA7BAC3);
  static const darkBorder = Color(0xFF2B4653);
  static const darkHeaderBg = Color(0xFF0D1820);
}

/// Mode-aware surface, text and border tokens.
///
/// Exposed as a [ThemeExtension] so widgets read them from
/// `context.mv` instead of hard-coding a light-only colour. Every storefront
/// widget pulls its backgrounds, borders and text from here, which is what
/// keeps the whole app legible when the dark-mode toggle flips the theme.
@immutable
class MvPalette extends ThemeExtension<MvPalette> {
  const MvPalette({
    required this.page,
    required this.surface,
    required this.surfaceMuted,
    required this.soft,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accentDeep,
    required this.onAccent,
    required this.shadow,
  });

  /// Light-mode tokens.
  factory MvPalette.light() => const MvPalette(
    page: MvColors.page,
    surface: Colors.white,
    surfaceMuted: MvColors.surface2,
    soft: MvColors.soft,
    border: MvColors.border,
    text: MvColors.ink,
    textMuted: MvColors.muted,
    accentDeep: MvColors.primaryDeep,
    onAccent: Colors.white,
    shadow: Color(0x14000000),
  );

  /// Dark-mode tokens. Surfaces step up from the page background so cards stay
  /// separable, and the deep sky-blue swaps to its light variant because
  /// `#168DB8` is unreadable on `#13232C`.
  factory MvPalette.dark() => const MvPalette(
    page: MvColors.darkPage,
    surface: MvColors.darkSurface,
    surfaceMuted: MvColors.darkSurface2,
    soft: MvColors.darkSoft,
    border: MvColors.darkBorder,
    text: MvColors.darkText,
    textMuted: MvColors.darkMuted,
    accentDeep: MvColors.accentLight,
    onAccent: MvColors.darkPage,
    shadow: Color(0x66000000),
  );

  /// Page background behind cards and bars.
  final Color page;

  /// Card, top-bar, sheet and floating-bar background.
  final Color surface;

  /// Chips, inputs and other recessed fills.
  final Color surfaceMuted;

  /// Brand-tinted fill for placeholders, avatars and empty states.
  final Color soft;

  /// Hairline borders on cards, bars and inputs.
  final Color border;

  /// High-contrast body text.
  final Color text;

  /// De-emphasised supporting text.
  final Color textMuted;

  /// Deep sky-blue for brand glyphs; brightened in dark mode.
  final Color accentDeep;

  /// Text and icons drawn on top of a sky-blue fill.
  final Color onAccent;

  /// Drop-shadow colour for floating surfaces.
  final Color shadow;

  @override
  MvPalette copyWith({
    Color? page,
    Color? surface,
    Color? surfaceMuted,
    Color? soft,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? accentDeep,
    Color? onAccent,
    Color? shadow,
  }) {
    return MvPalette(
      page: page ?? this.page,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      soft: soft ?? this.soft,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      accentDeep: accentDeep ?? this.accentDeep,
      onAccent: onAccent ?? this.onAccent,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  MvPalette lerp(covariant MvPalette? other, double t) {
    if (other == null) return this;
    return MvPalette(
      page: Color.lerp(page, other.page, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension MvThemeX on BuildContext {
  /// Mode-aware design tokens for the active theme.
  MvPalette get mv => Theme.of(this).extension<MvPalette>()!;

  /// True while the dark theme is on screen.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Optional persistent store for the theme preference.
///
/// `main()` resolves the real instance before the first frame and overrides
/// this with it; when it is null (widget tests, or any embedding that has not
/// loaded storage yet) the theme simply stays in memory.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

const String _themeModeKey = 'mvec.theme_mode';

/// Theme flicker controlled at app level and persisted across launches.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider)?.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.light,
    );
  }

  /// Switches between the light and dark themes.
  void toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  /// Applies [mode] and remembers it for the next launch.
  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider)?.setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Light theme, built once and shared.
final lightAppTheme = buildAppTheme(Brightness.light);

/// Dark theme, built once and shared.
final darkAppTheme = buildAppTheme(Brightness.dark);

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? MvPalette.dark() : MvPalette.light();
  final page = palette.page;
  final surface = palette.surface;
  final surface2 = palette.surfaceMuted;
  final text = palette.text;
  final muted = palette.textMuted;
  final border = palette.border;
  final headerBg = isDark ? MvColors.darkHeaderBg : surface;

  final base = ThemeData(brightness: brightness, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: page,
    canvasColor: surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MvColors.skyBlue,
      brightness: brightness,
      primary: MvColors.skyBlue,
      surface: surface,
    ),
    extensions: <ThemeExtension<dynamic>>[palette],
    dividerColor: border,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    textTheme: GoogleFonts.dmSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: text, displayColor: text),
    appBarTheme: AppBarTheme(
      backgroundColor: headerBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: text),
      titleTextStyle: GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: text,
      ),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
    dialogTheme: DialogThemeData(backgroundColor: surface),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: GoogleFonts.dmSans(fontSize: 13, color: muted),
      labelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: muted,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: MvColors.skyBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: MvColors.errorText),
      ),
    ),
    // Primary CTAs ("Add to Cart", "Shop Now", "Checkout") are sky blue.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MvColors.skyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MvColors.skyBlue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: MvColors.skyBlue),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: MvColors.skyBlue,
      unselectedLabelColor: muted,
      indicatorColor: MvColors.skyBlue,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: text,
      contentTextStyle: GoogleFonts.dmSans(color: page),
      behavior: SnackBarBehavior.floating,
    ),
    tooltipTheme: const TooltipThemeData(),
    // Active category filters fill with the sky-blue accent.
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: surface2,
      selectedColor: MvColors.skyBlue,
      checkmarkColor: Colors.white,
      labelStyle: GoogleFonts.dmSans(fontSize: 12, color: text),
      secondaryLabelStyle: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: border),
    ),
    // Count badges pinned to top-bar icons are sky blue, not the M3 error red.
    badgeTheme: BadgeThemeData(
      backgroundColor: MvColors.skyBlue,
      textColor: Colors.white,
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

extension MvHeadingX on BuildContext {
  TextStyle get mvH1 => GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Theme.of(this).colorScheme.onSurface,
  );
  TextStyle get mvEyebrow => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: mv.accentDeep,
  );
}
