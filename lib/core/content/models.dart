import 'package:flutter/foundation.dart';

@immutable
class VerseRange {
  const VerseRange(
      {required this.surah, required this.startAyah, required this.endAyah})
      : assert(startAyah > 0),
        assert(endAyah >= startAyah);

  final int surah;
  final int startAyah;
  final int endAyah;

  String get label =>
      startAyah == endAyah ? '$surah:$startAyah' : '$surah:$startAyah–$endAyah';
}

@immutable
class QuranVerse {
  const QuranVerse(
      {required this.key,
      required this.surah,
      required this.ayah,
      required this.arabic});
  final String key;
  final int surah;
  final int ayah;
  final String arabic;

  factory QuranVerse.fromJson(Map<String, Object?> json) => QuranVerse(
        key: json['key']! as String,
        surah: json['surah']! as int,
        ayah: json['ayah']! as int,
        arabic: json['arabic']! as String,
      );
}

@immutable
class TranslationEntry {
  const TranslationEntry(
      {required this.translation,
      required this.translator,
      required this.source});
  final String translation;
  final String translator;
  final String source;

  factory TranslationEntry.fromJson(Map<String, Object?> json) =>
      TranslationEntry(
        translation: json['translation']! as String,
        translator: json['translator']! as String,
        source: json['source']! as String,
      );
}

@immutable
class QuranExample {
  const QuranExample({
    required this.id,
    required this.range,
    required this.image,
    required this.category,
    required this.featured,
    required this.tags,
    this.title,
    this.chapterName,
    this.audioUrl,
    this.audioAssets = const [],
  });
  final String id;
  final VerseRange range;
  final String image;
  final String category;
  final bool featured;
  final List<String> tags;
  final String? title;
  final String? chapterName;
  final String? audioUrl;
  final List<String> audioAssets;

  factory QuranExample.fromJson(Map<String, Object?> json) => QuranExample(
        id: json['id']! as String,
        range: VerseRange(
          surah: json['surah']! as int,
          startAyah: json['ayahStart']! as int,
          endAyah: json['ayahEnd']! as int,
        ),
        image: json['image']! as String,
        category: json['category']! as String,
        featured: json['featured'] as bool? ?? false,
        tags: (json['tags'] as List<Object?>? ?? const []).cast<String>(),
        title: json['title'] as String?,
        chapterName: json['chapterName'] as String?,
        audioUrl: json['audioUrl'] as String?,
        audioAssets:
            (json['audioAssets'] as List<Object?>? ?? const []).cast<String>(),
      );
}
