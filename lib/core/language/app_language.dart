import 'package:flutter/widgets.dart';

@immutable
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.direction,
    this.hasTranslation = true,
    this.hasUiLocalization = true,
  });

  final String code;
  final String name;
  final String nativeName;
  final TextDirection direction;
  final bool hasTranslation;
  final bool hasUiLocalization;

  Locale get locale => Locale(code);
}

abstract final class AppLanguages {
  static const supported = <AppLanguage>[
    AppLanguage(
        code: 'ar',
        name: 'Arabic',
        nativeName: 'العربية',
        direction: TextDirection.rtl,
        hasTranslation: false),
    AppLanguage(
        code: 'en',
        name: 'English',
        nativeName: 'English',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'ur',
        name: 'Urdu',
        nativeName: 'اردو',
        direction: TextDirection.rtl),
    AppLanguage(
        code: 'hi',
        name: 'Hindi',
        nativeName: 'हिन्दी',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'id',
        name: 'Indonesian',
        nativeName: 'Bahasa Indonesia',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'tr',
        name: 'Turkish',
        nativeName: 'Türkçe',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'fr',
        name: 'French',
        nativeName: 'Français',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'es',
        name: 'Spanish',
        nativeName: 'Español',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'de',
        name: 'German',
        nativeName: 'Deutsch',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'bn',
        name: 'Bengali',
        nativeName: 'বাংলা',
        direction: TextDirection.ltr),
    AppLanguage(
        code: 'zh',
        name: 'Chinese',
        nativeName: '中文',
        direction: TextDirection.ltr,
        hasUiLocalization: false),
    AppLanguage(
        code: 'ja',
        name: 'Japanese',
        nativeName: '日本語',
        direction: TextDirection.ltr,
        hasUiLocalization: false),
    AppLanguage(
        code: 'ru',
        name: 'Russian',
        nativeName: 'Русский',
        direction: TextDirection.ltr,
        hasUiLocalization: false),
  ];

  static List<AppLanguage> get uiSupported => supported
      .where((language) => language.hasUiLocalization)
      .toList(growable: false);

  static List<AppLanguage> get translations => supported
      .where((language) => language.hasTranslation)
      .toList(growable: false);

  static AppLanguage byCode(String code) => supported.firstWhere(
        (language) => language.code == code,
        orElse: () => supported[1],
      );
}
