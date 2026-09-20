import 'package:flutter_test/flutter_test.dart';
import 'package:quran_examples/core/content/models.dart';
import 'package:quran_examples/features/share/domain/share_models.dart';
import 'package:quran_examples/features/share/services/share_service.dart';

void main() {
  const example = QuranExample(
    id: 'test',
    range: VerseRange(surah: 2, startAyah: 26, endAyah: 27),
    image: 'image.webp',
    category: 'test',
    featured: false,
    tags: [],
  );

  test('share text uses selected stored translation and range', () {
    const content = ShareContent(
      example: example,
      verses: [
        QuranVerse(key: '2:26', surah: 2, ayah: 26, arabic: 'arabic-26'),
        QuranVerse(key: '2:27', surah: 2, ayah: 27, arabic: 'arabic-27'),
      ],
      translations: ['urdu-26', 'urdu-27'],
      languageCode: 'ur',
      languageName: 'اردو',
    );
    final text = const ShareService()
        .createShareText(content, unavailableLabel: 'unavailable');
    expect(text, contains('arabic-26 arabic-27'));
    expect(text, contains('Surah 2:26–27'));
    expect(text, contains('urdu-26\nurdu-27'));
  });

  test('missing translation displays explicit unavailable text', () {
    const content = ShareContent(
      example: example,
      verses: [QuranVerse(key: '2:26', surah: 2, ayah: 26, arabic: 'verified')],
      translations: [],
      languageCode: 'fr',
      languageName: 'Français',
    );
    expect(
        const ShareService().createShareText(content,
            unavailableLabel: 'Translation unavailable'),
        contains('Translation unavailable'));
  });
}
