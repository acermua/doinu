import 'dart:collection';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  /// Core colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  /// Brand (client-provided)
  static const Color accent = Color(0xFFFF1DA0);
  static const Color brandGrey = Color(0xFF333333);
  static const Color appGreen = Color(0xFF1DB954);

  /// Accent variants
  static const Color accentLight = Color(0xFFFF4DB8); // hover / highlights
  static const Color accentDark = Color(0xFFE00087); // pressed / emphasis

  /// White alpha variants
  static const Color white80 = Color(0xCCFFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white40 = Color(0x66FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);

  /// Backgrounds
  static const Color bg = Color(0xFF121212);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardBorder = Color(0xFF2A2A2A);

  /// Text colors
  static const Color textPrimary = white;
  static const Color textMuted = Color(0xFFB3B3B3);
  static const Color textDisabled = Color(0xFF777777);
  static const Color textError = Color(0xFFE85C5C);

  /// Utility
  static const Color divider = Color(0xFF2A2A2A);
  static const Color overlay = Color(0xAA000000);

  /// Radius
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius rounded20 = BorderRadius.all(Radius.circular(20));
  static const BorderRadius rounded32 = BorderRadius.all(Radius.circular(32));

  /// Typography

  static TextStyle textTheme({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
    double height = 1.25,
    double letterSpacing = -0.1,
  }) {
    return GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static final text = _TextTheme();

  /// Spotify-style hierarchy (kept)
  static final TextTheme doinuTextTheme = TextTheme(
    displayLarge: GoogleFonts.figtree(
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      height: 1.1,
      color: textPrimary,
    ),
    headlineLarge: GoogleFonts.figtree(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      height: 1.1,
      color: textPrimary,
    ),
    titleLarge: GoogleFonts.figtree(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.2,
      color: textPrimary,
    ),
    titleMedium: GoogleFonts.figtree(
      fontWeight: FontWeight.w500,
      letterSpacing: -0.4,
      height: 1.2,
      color: textPrimary,
    ),
    bodyLarge: GoogleFonts.figtree(
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: -0.2,
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.figtree(
      fontWeight: FontWeight.w400,
      height: 1.25,
      color: textPrimary,
    ),
    labelLarge: GoogleFonts.figtree(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      height: 1.1,
      color: textPrimary,
    ),
  );

  /// Material Theme
  static ThemeData materialTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,

    primaryColor: accent,
    dividerColor: divider,

    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: bg,
      error: textError,
      onPrimary: white,
      onSurface: white,
    ),

    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: rounded20,
        side: BorderSide(color: cardBorder),
      ),
    ),

    textTheme: doinuTextTheme,
  );
}

class _TextTheme {
  /// Headings
  TextStyle get h1 =>
      AppTheme.textTheme(size: 32, weight: FontWeight.w700, height: 1.15);

  TextStyle get h2 =>
      AppTheme.textTheme(size: 24, weight: FontWeight.w600, height: 1.2);

  TextStyle get h3 =>
      AppTheme.textTheme(size: 20, weight: FontWeight.w600, height: 1.2);

  /// Body
  TextStyle get body => AppTheme.textTheme(size: 14, weight: FontWeight.w400);

  TextStyle get bodyMuted =>
      AppTheme.textTheme(size: 14, color: AppTheme.textMuted);

  /// Labels
  TextStyle get label =>
      AppTheme.textTheme(size: 12, weight: FontWeight.w500, height: 1.1);

  TextStyle get labelMuted => AppTheme.textTheme(
    size: 12,
    weight: FontWeight.w500,
    color: AppTheme.textMuted,
  );

  /// Errors
  TextStyle get error => AppTheme.textTheme(
    size: 12,
    color: AppTheme.textError,
    weight: FontWeight.w500,
  );
}

class ColourMatch {
  static const int _maxEntries = 80;

  static final LinkedHashMap<String, Color> _colorCache =
      LinkedHashMap<String, Color>();

  static final Map<String, Future<Color>> _inFlight = {};

  static Color? get(String url) {
    final color = _colorCache.remove(url);
    if (color != null) {
      _colorCache[url] = color; // LRU refresh
    }
    return color;
  }

  static void put(String url, Color color) {
    if (_colorCache.length >= _maxEntries) {
      _colorCache.remove(_colorCache.keys.first);
    }
    _colorCache[url] = color;
  }

  static Future<Color>? inFlight(String url) => _inFlight[url];
  static void setInFlight(String url, Future<Color> future) {
    _inFlight[url] = future;
  }

  static void clearInFlight(String url) {
    _inFlight.remove(url);
  }
}

Future<Color> getDominantColorFromImage(String url) {
  final cached = ColourMatch.get(url);
  if (cached != null) {
    debugPrint('🎨 material color cache hit');
    return Future.value(cached);
  }

  final inflight = ColourMatch.inFlight(url);
  if (inflight != null) {
    debugPrint('🎨 material color inflight reuse');
    return inflight;
  }

  final provider = CachedNetworkImageProvider(url);

  final future =
      ColorScheme.fromImageProvider(
            provider: provider,
            brightness: Brightness.dark,
          )
          .then((scheme) {
            final color = scheme.surface;
            ColourMatch.put(url, color);
            return color;
          })
          .catchError((e) {
            debugPrint('❌ material color error: $e');
            return Colors.indigo.shade800;
          })
          .whenComplete(() {
            ColourMatch.clearInFlight(url);
          });

  ColourMatch.setInFlight(url, future);
  return future;
}

// lighter but safe
Color getDominantLighter(Color? color, {double lightenFactor = 0.22}) {
  final baseColor = color ?? Colors.indigo.shade800;
  final hsl = HSLColor.fromColor(baseColor);

  final newLight = (hsl.lightness + lightenFactor).clamp(0.0, 0.75);
  final newSat = max(hsl.saturation, 0.25);

  return hsl.withLightness(newLight).withSaturation(newSat).toColor();
}

// darker but not dead black
Color getDominantDarker(Color? color, {double darkenFactor = 0.18}) {
  final baseColor = color ?? Colors.indigo.shade800;
  final hsl = HSLColor.fromColor(baseColor);

  final newLight = (hsl.lightness - darkenFactor).clamp(0.12, 1.0);
  final newSat = (hsl.saturation + 0.1).clamp(0.0, 1.0);

  return hsl.withLightness(newLight).withSaturation(newSat).toColor();
}
