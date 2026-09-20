import 'dart:convert';
import 'dart:io';

const languageFields = <String, String>{
  'english': 'en',
  'spanish': 'es',
  'urdu': 'ur',
  'turkish': 'tr',
  'chinses': 'zh',
  'japanses': 'ja',
  'russian': 'ru',
};

Never _fail(String message) {
  stderr.writeln(message);
  exitCode = 2;
  throw StateError(message);
}

void main(List<String> arguments) {
  if (arguments.length != 2) {
    _fail(
        'Usage: dart run tool/import_legacy_dataset.dart <source.json> <project-root>');
  }
  final source = File(arguments[0]);
  final root = Directory(arguments[1]);
  if (!source.existsSync()) _fail('Source file not found: ${source.path}');

  final decoded = jsonDecode(source.readAsStringSync()) as Map<String, Object?>;
  final quran =
      (decoded['Quran'] as Map<Object?, Object?>).cast<String, Object?>();
  final rows = (quran['example'] as List<Object?>)
      .map((value) => (value as Map<Object?, Object?>).cast<String, Object?>())
      .toList(growable: false);

  final examples = <Map<String, Object?>>[];
  final verses = <Map<String, Object?>>[];
  final translations = <String, Map<String, Map<String, String>>>{
    for (final code in languageFields.values) code: {},
  };
  final seenPassages = <String>{};

  for (final row in rows) {
    final surah = row['chapter_no'] as int;
    final ayahs = RegExp(r'\d+')
        .allMatches(row['aya_no'].toString())
        .map((match) => int.parse(match.group(0)!))
        .toList(growable: false);
    if (ayahs.isEmpty) _fail('Missing ayah number at index ${row['index']}');
    final start = ayahs.first;
    final end = ayahs.length == 1 ? start : ayahs.last;
    final passageKey = start == end ? '$surah:$start' : '$surah:$start-$end';
    if (!seenPassages.add(passageKey)) _fail('Duplicate passage: $passageKey');

    // Multi-ayah source rows are deliberately kept as a single verbatim passage.
    // Splitting them would require inventing boundaries not present in the source.
    verses.add({
      'key': '$surah:$start',
      'surah': surah,
      'ayah': start,
      if (end != start) 'ayahEnd': end,
      'arabic': row['arabic'].toString().trim(),
      'source': 'User-supplied legacy quranExample.json',
      'verified': false,
    });

    final index = row['index'] as int;
    examples.add({
      'id': 'legacy_$index',
      'title': row['short_title'].toString().trim(),
      'surah': surah,
      'ayahStart': start,
      'ayahEnd': end,
      'image': '',
      'category': 'legacy',
      'featured': index <= 5,
      'tags': <String>[],
      'chapterName': row['chapter_name'].toString().trim(),
      'audioUrl': row['mp3_file_path'].toString().trim(),
      'hasAudio': row['hasAudio'] == true,
      'legacyIndex': index,
      'verified': false,
    });

    for (final field in languageFields.entries) {
      final text = row[field.key]?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      translations[field.value]!['$surah:$start'] = {
        'translation': text,
        'translator': 'Not provided',
        'source': 'User-supplied legacy quranExample.json',
        'verified': 'false',
      };
    }
  }

  const encoder = JsonEncoder.withIndent('  ');
  void write(String relativePath, Object value) {
    final file = File('${root.path}${Platform.pathSeparator}$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('${encoder.convert(value)}\n');
  }

  write('assets/data/examples.json', examples);
  write('assets/data/quran/verses.json', verses);
  for (final item in translations.entries) {
    write('assets/data/translations/${item.key}.json', item.value);
  }
  write('assets/data/legacy/import_manifest.json', {
    'sourceFile': source.path,
    'sourceVersion': quran['version'],
    'importedRecords': rows.length,
    'verificationStatus': 'unverified',
    'notes': 'Text preserved verbatim; multi-ayah passages were not split.',
  });
  stdout.writeln('Imported ${rows.length} legacy passages.');
}
