import 'package:flutter/material.dart';
import '../../../../core/ads/ad_service.dart';
import '../../../../core/content/repositories.dart';
import '../../../../core/language/app_language.dart';
import '../../../../core/settings/language_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/language_sheet.dart';
import '../../domain/share_models.dart';
import '../../services/share_service.dart';
import '../widgets/share_card.dart';

class SharePreviewScreen extends StatefulWidget {
  const SharePreviewScreen({
    super.key,
    required this.initialContent,
    required this.languages,
    required this.translations,
    this.shareService = const ShareService(),
  });
  final ShareContent initialContent;
  final LanguageController languages;
  final QuranTranslationRepository translations;
  final ShareService shareService;

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final _boundaryKey = GlobalKey();
  late ShareContent _content = widget.initialContent;
  ShareCardStyle _style = ShareCardStyle.fullImage;
  bool _busy = false;

  Future<void> _changeLanguage(String code) async {
    final range = _content.example.range;
    final translated = await widget.translations.getVerseRange(
      surah: range.surah,
      startAyah: range.startAyah,
      endAyah: range.endAyah,
      language: code,
    );
    if (!mounted) return;
    final language = AppLanguages.byCode(code);
    setState(() => _content = _content.copyWith(
          translations: translated,
          languageCode: code,
          languageName: language.nativeName,
        ));
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await widget.shareService.shareCard(_boundaryKey);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.fullImage, l10n.imageVerse, l10n.minimal];
    return Scaffold(
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AdBannerSlot(),
      ),
      appBar: AppBar(title: Text(l10n.preview)),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(28, 8, 28, 12),
                child: RepaintBoundary(
                    key: _boundaryKey,
                    child: ShareCard(content: _content, style: _style)),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: SegmentedButton<ShareCardStyle>(
              segments: [
                for (var i = 0; i < ShareCardStyle.values.length; i++)
                  ButtonSegment(
                      value: ShareCardStyle.values[i], label: Text(labels[i]))
              ],
              selected: {_style},
              onSelectionChanged: (value) =>
                  setState(() => _style = value.first),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                icon: const Icon(Icons.translate),
                label: Text(_content.languageName),
                onPressed: _content.arabicOnly
                    ? null
                    : () => showLanguageSheet(
                          context: context,
                          selectedCode: _content.languageCode,
                          onSelected: _changeLanguage,
                        ),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.translation)),
                  ButtonSegment(value: true, label: Text(l10n.arabicOnly)),
                ],
                selected: {_content.arabicOnly},
                onSelectionChanged: (value) => setState(() =>
                    _content = _content.copyWith(arabicOnly: value.first)),
              )),
            ]),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              onPressed: _busy ? null : _share,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.ios_share),
              label: Text(l10n.share),
            ),
          ),
        ]),
      ),
    );
  }
}
