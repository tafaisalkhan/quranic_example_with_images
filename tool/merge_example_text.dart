import 'dart:convert';
import 'dart:io';

Never fail(String message) {
  stderr.writeln(message);
  exitCode = 2;
  throw StateError(message);
}

Map<String, Object?> readObject(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map<Object?, Object?>)
        .cast<String, Object?>();

List<Map<String, Object?>> readList(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as List<Object?>)
        .map(
            (value) => (value as Map<Object?, Object?>).cast<String, Object?>())
        .toList();

void writeJson(String path, Object value) => File(path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(value)}\n',
    );

void main(List<String> arguments) {
  if (arguments.length != 2) {
    fail(
        'Usage: dart run tool/merge_example_text.dart <source.txt> <project-root>');
  }
  final source = File(arguments[0]);
  final root = arguments[1];
  if (!source.existsSync()) fail('Source file not found: ${source.path}');

  final examplesPath =
      '$root${Platform.pathSeparator}assets${Platform.pathSeparator}data${Platform.pathSeparator}examples.json';
  final versesPath =
      '$root${Platform.pathSeparator}assets${Platform.pathSeparator}data${Platform.pathSeparator}quran${Platform.pathSeparator}verses.json';
  final englishPath =
      '$root${Platform.pathSeparator}assets${Platform.pathSeparator}data${Platform.pathSeparator}translations${Platform.pathSeparator}en.json';
  final manifestPath =
      '$root${Platform.pathSeparator}assets${Platform.pathSeparator}data${Platform.pathSeparator}legacy${Platform.pathSeparator}text_merge_manifest.json';

  final examples = readList(examplesPath);
  final verses = readList(versesPath);
  final english = readObject(englishPath);
  final originalExampleCount = examples.length;
  final originalVerseCount = verses.length;
  final originalTranslationCount = english.length;

  final text = source.readAsStringSync();
  final heading = RegExp(
    r"^(\d+)\.\s+(.+?)\s+(\d+):(\d+)(?:(?:–|-)(\d+))?\s+—\s+(.+?)\s*$",
    multiLine: true,
  );
  final matches = heading.allMatches(text).toList(growable: false);
  final added = <String>[];
  final covered = <String>[];
  final ambiguous = <String>[];

  bool containsRange(int surah, int start, int end) => examples.any((item) =>
      item['surah'] == surah &&
      (item['ayahStart'] as int) <= start &&
      (item['ayahEnd'] as int) >= end);

  bool overlapsRange(int surah, int start, int end) => examples.any((item) =>
      item['surah'] == surah &&
      (item['ayahStart'] as int) <= end &&
      (item['ayahEnd'] as int) >= start);

  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final chapterName = match.group(2)!.trim();
    final surah = int.parse(match.group(3)!);
    final start = int.parse(match.group(4)!);
    final end = match.group(5) == null ? start : int.parse(match.group(5)!);
    final title = match.group(6)!.trim();
    final reference = '$surah:$start${end == start ? '' : '–$end'}';

    if (containsRange(surah, start, end)) {
      covered.add(reference);
      continue;
    }
    if (overlapsRange(surah, start, end)) {
      ambiguous.add(reference);
      continue;
    }

    final blockEnd =
        index + 1 < matches.length ? matches[index + 1].start : text.length;
    final block = text.substring(match.end, blockEnd);
    final arabicMatch = RegExp(
      r'Arabic:\s*\r?\n([\s\S]*?)\r?\n\s*English:',
    ).firstMatch(block);
    final englishMatch = RegExp(
      r'English:\s*\r?\n([\s\S]*?)(?:\r?\n\s*Visual:|$)',
    ).firstMatch(block);
    final visualMatch = RegExp(r'Visual:\s*([^\r\n]+)').firstMatch(block);
    if (arabicMatch == null || englishMatch == null) {
      ambiguous.add('$reference (missing text section)');
      continue;
    }
    final arabic = arabicMatch.group(1)!.trim();
    final translation = englishMatch.group(1)!.trim();
    if (arabic.isEmpty || translation.isEmpty) {
      ambiguous.add('$reference (empty content)');
      continue;
    }

    final key = '$surah:$start';
    if (verses.any((verse) => verse['key'] == key) ||
        english.containsKey(key)) {
      ambiguous.add('$reference (key collision)');
      continue;
    }
    examples.add({
      'id': 'text_${surah}_$start${end == start ? '' : '_$end'}',
      'title': title,
      'surah': surah,
      'ayahStart': start,
      'ayahEnd': end,
      'image': '',
      'category': 'text_import',
      'featured': false,
      'tags': [title.toLowerCase()],
      'chapterName': chapterName,
      'audioUrl': null,
      'hasAudio': false,
      'verified': false,
      if (visualMatch != null)
        'visualDescription': visualMatch.group(1)!.trim(),
    });
    verses.add({
      'key': key,
      'surah': surah,
      'ayah': start,
      if (end != start) 'ayahEnd': end,
      'arabic': arabic,
      'source': 'User-supplied exampleinquran.txt',
      'verified': false,
    });
    english[key] = {
      'translation': translation,
      'translator': 'Not provided',
      'source': 'User-supplied exampleinquran.txt',
      'verified': false,
    };
    added.add(reference);
  }

  if (examples.length < originalExampleCount ||
      verses.length < originalVerseCount ||
      english.length < originalTranslationCount) {
    fail('Merge attempted to remove existing data; no files were written.');
  }
  writeJson(examplesPath, examples);
  writeJson(versesPath, verses);
  writeJson(englishPath, english);
  writeJson(manifestPath, {
    'sourceFile': source.path,
    'sourceEntries': matches.length,
    'existingExamplesBefore': originalExampleCount,
    'existingExamplesAfter': examples.length,
    'added': added,
    'alreadyCovered': covered,
    'ambiguousNotChanged': ambiguous,
    'verificationStatus': 'unverified',
  });
  stdout.writeln('Added ${added.length}: ${added.join(', ')}');
  stdout.writeln('Already covered ${covered.length}: ${covered.join(', ')}');
  stdout.writeln('Ambiguous ${ambiguous.length}: ${ambiguous.join(', ')}');
}
