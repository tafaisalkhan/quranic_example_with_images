import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
        'Usage: dart run tool/assign_indexed_images.dart <project-root>');
    exitCode = 2;
    return;
  }
  final root = arguments.single;
  final separator = Platform.pathSeparator;
  final examplesFile = File(
    '$root${separator}assets${separator}data${separator}examples.json',
  );
  final imageDirectory = Directory(
    '$root${separator}assets${separator}images${separator}examples',
  );
  final examples = (jsonDecode(examplesFile.readAsStringSync())
          as List<Object?>)
      .map((value) => (value as Map<Object?, Object?>).cast<String, Object?>())
      .toList();
  final assigned = <int>[];
  final missing = <int>[];
  for (var index = 0; index < examples.length; index++) {
    final number = index + 1;
    final candidates = ['png', 'webp', 'jpg', 'jpeg']
        .map((extension) =>
            File('${imageDirectory.path}$separator$number.$extension'))
        .where((file) => file.existsSync())
        .toList(growable: false);
    if (candidates.isEmpty) {
      missing.add(number);
      continue;
    }
    final extension = candidates.first.path.split('.').last;
    examples[index]['image'] = 'assets/images/examples/$number.$extension';
    assigned.add(number);
  }
  examplesFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(examples)}\n',
  );
  stdout.writeln('Assigned ${assigned.length} images: ${assigned.join(', ')}');
  stdout.writeln('Missing ${missing.length} images: ${missing.join(', ')}');
}
