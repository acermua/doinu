import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'language_provider.g.dart';

@Riverpod(keepAlive: true)
class Language extends _$Language {
  static const String _kLanguageCode = 'language_code';

  @override
  FutureOr<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_kLanguageCode);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = AsyncData(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageCode, locale.languageCode);
  }
}
