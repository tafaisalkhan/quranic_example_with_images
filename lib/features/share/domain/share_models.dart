import '../../../core/content/models.dart';

enum ShareCardStyle { fullImage, imageVerse, minimal }

class ShareContent {
  const ShareContent({
    required this.example,
    required this.verses,
    required this.translations,
    required this.languageCode,
    required this.languageName,
    this.arabicOnly = false,
  });
  final QuranExample example;
  final List<QuranVerse> verses;
  final List<String> translations;
  final String languageCode;
  final String languageName;
  final bool arabicOnly;

  String get arabic => verses.map((verse) => verse.arabic).join(' ');
  String get translatedText => translations.join('\n');
  String get reference => 'Surah ${example.range.label}';

  ShareContent copyWith(
          {List<String>? translations,
          String? languageCode,
          String? languageName,
          bool? arabicOnly}) =>
      ShareContent(
        example: example,
        verses: verses,
        translations: translations ?? this.translations,
        languageCode: languageCode ?? this.languageCode,
        languageName: languageName ?? this.languageName,
        arabicOnly: arabicOnly ?? this.arabicOnly,
      );
}
