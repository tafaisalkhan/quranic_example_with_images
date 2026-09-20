import 'models.dart';

abstract interface class QuranRepository {
  Future<QuranVerse?> getVerse({required int surah, required int ayah});
  Future<List<QuranVerse>> getVerseRange(VerseRange range);
}

abstract interface class QuranTranslationRepository {
  Future<String?> getTranslation(
      {required int surah, required int ayah, required String language});
  Future<List<String>> getVerseRange({
    required int surah,
    required int startAyah,
    required int endAyah,
    required String language,
  });
  Future<TranslationEntry?> getEntry(
      {required int surah, required int ayah, required String language});
}

abstract interface class ExampleRepository {
  Future<List<QuranExample>> getExamples();
}
