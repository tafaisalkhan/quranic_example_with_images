import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/share_models.dart';

class ShareService {
  const ShareService();

  String createShareText(ShareContent content,
      {required String unavailableLabel}) {
    final buffer = StringBuffer()
      ..writeln(content.arabic)
      ..writeln()
      ..writeln(content.reference);
    if (!content.arabicOnly) {
      buffer
        ..writeln()
        ..writeln(content.languageName)
        ..writeln(content.translatedText.isEmpty
            ? unavailableLabel
            : content.translatedText);
    }
    buffer
      ..writeln()
      ..write('Examples in the Quran');
    return buffer.toString();
  }

  Future<void> shareText(ShareContent content,
          {required String unavailableLabel}) =>
      Share.share(createShareText(content, unavailableLabel: unavailableLabel));

  Future<void> copyText(ShareContent content,
          {required String unavailableLabel}) =>
      Clipboard.setData(ClipboardData(
          text: createShareText(content, unavailableLabel: unavailableLabel)));

  Future<XFile> captureCard(GlobalKey boundaryKey) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Share card is not ready');
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Unable to encode share card');
    return XFile.fromData(
      bytes.buffer.asUint8List(),
      mimeType: 'image/png',
      name: 'quran-example-${DateTime.now().millisecondsSinceEpoch}.png',
    );
  }

  Future<void> shareCard(GlobalKey boundaryKey) async {
    final file = await captureCard(boundaryKey);
    await Share.shareXFiles([file]);
  }

  Future<void> shareAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final extension = assetPath.split('.').last.toLowerCase();
    final file = XFile.fromData(
      data.buffer.asUint8List(),
      mimeType: 'image/$extension',
      name: 'quran-example-image.$extension',
    );
    await Share.shareXFiles([file]);
  }
}
