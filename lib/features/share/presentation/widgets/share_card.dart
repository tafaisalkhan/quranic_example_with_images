import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/language/app_language.dart';
import '../../domain/share_models.dart';

class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.content, required this.style});
  final ShareContent content;
  final ShareCardStyle style;

  Widget _image({BoxFit fit = BoxFit.cover}) => content.example.image.isEmpty
      ? const DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xff153c35), Color(0xff071c18)])),
        )
      : Image.asset(
          content.example.image,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xff153c35), Color(0xff071c18)])),
          ),
        );

  Widget _textBlock(BuildContext context,
          {Color color = Colors.white, bool centered = false}) =>
      Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              centered ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(content.arabic,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                      color: color,
                      fontSize: 25,
                      height: 1.8,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Text(content.reference,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                    color: color.withValues(alpha: .82), fontSize: 13)),
            if (!content.arabicOnly) ...[
              const SizedBox(height: 20),
              Text(content.languageName,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                      color: color.withValues(alpha: .75),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Directionality(
                textDirection:
                    AppLanguages.byCode(content.languageCode).direction,
                child: Text(content.translatedText,
                    textAlign: centered ? TextAlign.center : TextAlign.start,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 15, height: 1.45)),
              ),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final footer = PositionedDirectional(
      start: 24,
      end: 24,
      bottom: 15,
      child: Text('Examples in the Quran',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: .7),
              fontSize: 11,
              letterSpacing: 1)),
    );
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: switch (style) {
          ShareCardStyle.fullImage => Stack(fit: StackFit.expand, children: [
              _image(),
              const DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x44000000),
                  Color(0xf2000000)
                ],
                stops: [0, .38, 1],
              ))),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 32),
                      child: _textBlock(context))),
              footer,
            ]),
          ShareCardStyle.imageVerse => Stack(children: [
              Column(children: [
                Expanded(flex: 55, child: SizedBox.expand(child: _image())),
                Expanded(
                    flex: 45,
                    child: ColoredBox(
                        color: const Color(0xff09231e),
                        child: Center(
                            child: SingleChildScrollView(
                                child: _textBlock(context))))),
              ]),
              footer,
            ]),
          ShareCardStyle.minimal => Stack(fit: StackFit.expand, children: [
              ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: _image()),
              const ColoredBox(color: Color(0xbb061713)),
              Center(child: _textBlock(context, centered: true)),
              footer,
            ]),
        },
      ),
    );
  }
}
