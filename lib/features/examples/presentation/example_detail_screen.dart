import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/content/models.dart';
import '../../../core/content/repositories.dart';
import '../../../core/settings/language_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/language_sheet.dart';
import '../../share/domain/share_models.dart';
import '../../share/presentation/share_options_sheet.dart';
import 'example_topics.dart';

class ExampleDetailScreen extends StatelessWidget {
  const ExampleDetailScreen({
    super.key,
    required this.example,
    required this.languages,
    required this.quran,
    required this.translations,
  });
  final QuranExample example;
  final LanguageController languages;
  final QuranRepository quran;
  final QuranTranslationRepository translations;

  Future<ShareContent> _load() async {
    final verses = await quran.getVerseRange(example.range);
    final translated = await translations.getVerseRange(
      surah: example.range.surah,
      startAyah: example.range.startAyah,
      endAyah: example.range.endAyah,
      language: languages.translationLanguageCode,
    );
    return ShareContent(
      example: example,
      verses: verses,
      translations: translated,
      languageCode: languages.translationLanguageCode,
      languageName: languages.translationLanguage.nativeName,
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: languages,
        builder: (context, _) => FutureBuilder<ShareContent>(
          future: _load(),
          builder: (context, snapshot) {
            final l10n = AppLocalizations.of(context);
            final content = snapshot.data;
            return Scaffold(
              bottomNavigationBar: const SafeArea(
                top: false,
                child: AdBannerSlot(),
              ),
              extendBodyBehindAppBar: false,
              appBar: AppBar(
                centerTitle: true,
                toolbarHeight: 72,
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chapter ${example.range.surah} • Ayah ${example.range.label}',
                    ),
                    Text(
                      exampleTopic(example, languages.appLanguageCode),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              body: snapshot.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(slivers: [
                      SliverToBoxAdapter(
                        child: example.image.isNotEmpty
                            ? Hero(
                                tag: 'example-image-${example.id}',
                                child: _RecitationRevealImage(
                                  imagePath: example.image,
                                  audioAssets: example.audioAssets,
                                  arabicText: content?.arabic ?? '',
                                ),
                              )
                            : const ColoredBox(
                                color: Color(0xff153c35),
                                child: SizedBox(height: 520),
                              ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            20, 24, 20, 110),
                        sliver: SliverList.list(children: [
                          ExpansionTile(
                            key: PageStorageKey('translation-${example.id}'),
                            initiallyExpanded: true,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              'Translation • tap to show or hide',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            children: [
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.language),
                                  label: Text(
                                      languages.translationLanguage.nativeName),
                                  onPressed: () => showLanguageSheet(
                                    context: context,
                                    selectedCode:
                                        languages.translationLanguageCode,
                                    onSelected:
                                        languages.setTranslationLanguage,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Directionality(
                                textDirection:
                                    languages.translationLanguage.direction,
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    content == null ||
                                            content.translatedText.isEmpty
                                        ? l10n.translationUnavailable
                                        : content.translatedText,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(height: 1.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ]),
                      ),
                    ]),
              floatingActionButton: content == null || content.arabic.isEmpty
                  ? null
                  : FloatingActionButton.extended(
                      icon: const Icon(Icons.ios_share),
                      label: Text(l10n.share),
                      onPressed: () => showShareOptions(
                        context: context,
                        content: content,
                        languages: languages,
                        translations: translations,
                      ),
                    ),
            );
          },
        ),
      );
}

class _RecitationRevealImage extends StatefulWidget {
  const _RecitationRevealImage({
    required this.imagePath,
    required this.audioAssets,
    required this.arabicText,
  });

  final String imagePath;
  final List<String> audioAssets;
  final String arabicText;

  @override
  State<_RecitationRevealImage> createState() => _RecitationRevealImageState();
}

class _RecitationRevealImageState extends State<_RecitationRevealImage> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  bool _loading = false;
  bool _showAyah = false;
  int _currentTrack = 0;

  bool get _hasAudio => widget.audioAssets.isNotEmpty;
  bool get _isPlaying => _state == PlayerState.playing;
  double get _trackProgress => _duration.inMilliseconds == 0
      ? 0
      : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  double get _progress => !_hasAudio
      ? 1
      : ((_currentTrack + _trackProgress) / widget.audioAssets.length)
          .clamp(0.0, 1.0);

  String get _visibleAyah {
    final words = widget.arabicText.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty || _progress <= 0) return '';
    final visibleCount =
        (words.length * _progress).ceil().clamp(1, words.length);
    return words.take(visibleCount).join(' ');
  }

  AssetSource _sourceFor(int index) => AssetSource(
        widget.audioAssets[index].replaceFirst('assets/', ''),
      );

  Future<void> _playCurrentTrack() => _player.play(_sourceFor(_currentTrack));
  @override
  void initState() {
    super.initState();
    _subscriptions.add(_player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    }));
    _subscriptions.add(_player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    }));
    _subscriptions.add(_player.onPlayerComplete.listen((_) async {
      if (!mounted || _currentTrack + 1 >= widget.audioAssets.length) return;
      setState(() {
        _currentTrack++;
        _duration = Duration.zero;
        _position = Duration.zero;
        _loading = true;
      });
      await _playCurrentTrack();
    }));
    _subscriptions.add(_player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
          _loading = false;
          if (state == PlayerState.completed) _position = _duration;
        });
      }
    }));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasAudio && _state == PlayerState.stopped) {
        _togglePlayback();
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (!_hasAudio || _loading) return;
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    setState(() => _loading = true);
    try {
      if (_state == PlayerState.paused) {
        await _player.resume();
      } else {
        if (_state == PlayerState.completed) {
          _position = Duration.zero;
        }
        await _playCurrentTrack();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to play this recitation.')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Widget _buildAyahOverlay(BuildContext context) => Positioned.fill(
        child: Align(
          alignment: _showAyah ? Alignment.center : Alignment.topLeft,
          child: Padding(
            padding: _showAyah
                ? const EdgeInsets.symmetric(horizontal: 18)
                : const EdgeInsets.all(12),
            child: _showAyah
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .66),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .3),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                _visibleAyah,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  height: 1.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          top: 2,
                          end: 2,
                          child: IconButton(
                            tooltip: 'Hide Ayah',
                            onPressed: () => setState(() => _showAyah = false),
                            icon: const Icon(
                              Icons.visibility_off,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : IconButton.filled(
                    tooltip: 'Show Ayah',
                    onPressed: () => setState(() => _showAyah = true),
                    icon: const Icon(Icons.visibility),
                  ),
          ),
        ),
      );
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: AspectRatio(
              aspectRatio: 1145 / 1374,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: 14,
                        sigmaY: 14,
                      ),
                      child: Transform.scale(
                        scale: 1.08,
                        child: Image.asset(
                          widget.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xff153c35)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.zero,
                      child: ColorFiltered(
                        colorFilter: _hasAudio
                            ? const ColorFilter.mode(
                                Color(0xE6000000),
                                BlendMode.darken,
                              )
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.dst,
                              ),
                        child: Image.asset(
                          widget.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xff153c35)),
                        ),
                      ),
                    ),
                    if (_hasAudio)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final revealEdge =
                                constraints.maxHeight * _progress;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: ClipRect(
                                    clipper: _RevealClipper(_progress),
                                    child: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Image.asset(
                                        widget.imagePath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_progress > 0 && _progress < 1)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: revealEdge - 18,
                                    height: 36,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withValues(alpha: 0),
                                            Colors.white.withValues(
                                              alpha: _isPlaying ? .68 : .3,
                                            ),
                                            Colors.white.withValues(alpha: 0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (widget.arabicText.isNotEmpty)
                      _buildAyahOverlay(context),
                  ],
                ),
              ),
            ),
          ),
          if (_hasAudio)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _togglePlayback,
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    _isPlaying ? 'Pause recitation' : 'Play recitation',
                  ),
                ),
              ),
            ),
        ],
      );
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height * progress);

  @override
  bool shouldReclip(covariant _RevealClipper oldClipper) =>
      oldClipper.progress != progress;
}
