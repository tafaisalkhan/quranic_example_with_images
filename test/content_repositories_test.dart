import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_examples/core/content/asset_repositories.dart';
import 'package:quran_examples/core/content/models.dart';

class MemoryBundle extends CachingAssetBundle {
  MemoryBundle(this.assets);
  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Missing $key');
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }
}

void main() {
  test('canonical verse range preserves order and does not fill gaps',
      () async {
    final repository = AssetQuranRepository(
        bundle: MemoryBundle({
      'assets/data/quran/verses.json': jsonEncode([
        {'key': '14:24', 'surah': 14, 'ayah': 24, 'arabic': 'verified-24'},
        {'key': '14:25', 'surah': 14, 'ayah': 25, 'arabic': 'verified-25'},
      ]),
    }));

    final verses = await repository
        .getVerseRange(const VerseRange(surah: 14, startAyah: 24, endAyah: 26));
    expect(verses.map((verse) => verse.arabic), ['verified-24', 'verified-25']);
  });

  test('translation range returns stored values only', () async {
    final repository = AssetQuranTranslationRepository(
        bundle: MemoryBundle({
      'assets/data/translations/fr.json': jsonEncode({
        '2:26': {'translation': 'verified', 'translator': 't', 'source': 's'},
      }),
    }));

    expect(
        await repository.getVerseRange(
            surah: 2, startAyah: 26, endAyah: 27, language: 'fr'),
        ['verified']);
    expect(await repository.getTranslation(surah: 2, ayah: 27, language: 'fr'),
        isNull);
  });
}
