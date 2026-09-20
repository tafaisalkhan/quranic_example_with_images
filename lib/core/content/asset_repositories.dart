import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'repositories.dart';

class AssetQuranRepository implements QuranRepository {
  AssetQuranRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<Map<String, QuranVerse>>? _cache;

  Future<Map<String, QuranVerse>> _load() => _cache ??= () async {
        final raw = await _bundle.loadString('assets/data/quran/verses.json');
        final values =
            (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>();
        return {
          for (final value in values)
            value['key']! as String: QuranVerse.fromJson(value)
        };
      }();

  @override
  Future<QuranVerse?> getVerse({required int surah, required int ayah}) async =>
      (await _load())['$surah:$ayah'];

  @override
  Future<List<QuranVerse>> getVerseRange(VerseRange range) async {
    final data = await _load();
    return [
      for (var ayah = range.startAyah; ayah <= range.endAyah; ayah++)
        if (data['${range.surah}:$ayah'] case final verse?) verse,
    ];
  }
}

class AssetQuranTranslationRepository implements QuranTranslationRepository {
  AssetQuranTranslationRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  final Map<String, Future<Map<String, TranslationEntry>>> _cache = {};

  Future<Map<String, TranslationEntry>> _load(String language) =>
      _cache.putIfAbsent(language, () async {
        try {
          final raw = await _bundle
              .loadString('assets/data/translations/$language.json');
          final values = (jsonDecode(raw) as Map<String, Object?>);
          return values.map((key, value) => MapEntry(
                key,
                TranslationEntry.fromJson(
                    (value as Map<Object?, Object?>).cast<String, Object?>()),
              ));
        } on FlutterError {
          return {};
        }
      });

  @override
  Future<TranslationEntry?> getEntry(
          {required int surah,
          required int ayah,
          required String language}) async =>
      (await _load(language))['$surah:$ayah'];

  @override
  Future<String?> getTranslation(
          {required int surah,
          required int ayah,
          required String language}) async =>
      (await getEntry(surah: surah, ayah: ayah, language: language))
          ?.translation;

  @override
  Future<List<String>> getVerseRange(
      {required int surah,
      required int startAyah,
      required int endAyah,
      required String language}) async {
    final data = await _load(language);
    return [
      for (var ayah = startAyah; ayah <= endAyah; ayah++)
        if (data['$surah:$ayah'] case final entry?) entry.translation,
    ];
  }
}

class AssetExampleRepository implements ExampleRepository {
  AssetExampleRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  @override
  Future<List<QuranExample>> getExamples() async {
    final raw = await _bundle.loadString('assets/data/examples.json');
    return (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(QuranExample.fromJson)
        .toList(growable: false);
  }
}
