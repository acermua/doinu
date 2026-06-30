import 'package:flutter/material.dart';

import 'translations/translations.dart';
import 'translations/en.dart';
import 'translations/es.dart';
import 'translations/eu.dart';

class AppLocalizations {
  final Locale locale;
  late final Translations _translations;

  AppLocalizations(this.locale) {
    _translations = _resolveTranslations(locale);
  }

  static Translations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!
        ._translations;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Translations _resolveTranslations(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return EnglishTranslations();
      case 'es':
        return SpanishTranslations();
      case 'eu':
        return EuskaraTranslations();
      default:
        return EnglishTranslations();
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'eu'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
