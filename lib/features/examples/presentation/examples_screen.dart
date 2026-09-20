import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/content/models.dart';
import '../../../core/content/repositories.dart';
import '../../../core/engagement/engagement_controller.dart';
import '../../../core/settings/language_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/presentation/settings_screen.dart';
import 'example_detail_screen.dart';
import 'example_topics.dart';

class ExamplesScreen extends StatefulWidget {
  const ExamplesScreen({
    super.key,
    required this.languages,
    required this.engagement,
    required this.examples,
    required this.quran,
    required this.translations,
    this.initialFavoritesOnly = false,
  });
  final LanguageController languages;
  final EngagementController engagement;
  final ExampleRepository examples;
  final QuranRepository quran;
  final QuranTranslationRepository translations;
  final bool initialFavoritesOnly;

  @override
  State<ExamplesScreen> createState() => _ExamplesScreenState();
}

class _ExamplesScreenState extends State<ExamplesScreen> {
  late bool _favoritesOnly;
  late final Future<List<QuranExample>> _examplesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesOnly = widget.initialFavoritesOnly;
    _examplesFuture = widget.examples.getExamples();
  }

  bool _containsArabic(String value) =>
      RegExp(r'[\u0600-\u06ff]').hasMatch(value);

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const SafeArea(
          top: false,
          child: AdBannerSlot(),
        ),
        appBar: AppBar(
          title: const Text('Quranic Example'),
          actions: [
            IconButton(
              tooltip: _favoritesOnly ? 'Show all examples' : 'Show favorites',
              icon: Icon(
                _favoritesOnly ? Icons.favorite : Icons.favorite_border,
              ),
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(languages: widget.languages),
                  )),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<QuranExample>>(
                future: _examplesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? const [];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.engagement
                        .prepareDailyExample(data.map((e) => e.id).toList());
                  });
                  if (data.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(32),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_outlined, size: 52),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context).noExamples,
                              textAlign: TextAlign.center),
                        ]),
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final visibleData = _favoritesOnly
                          ? data
                              .where((item) =>
                                  widget.engagement.isFavorite(item.id))
                              .toList()
                          : data;
                      final columnCount = switch (constraints.maxWidth) {
                        >= 900 => 4,
                        >= 600 => 3,
                        _ => 2,
                      };
                      const cardAspectRatio = .72;

                      return GridView.builder(
                        padding: const EdgeInsetsDirectional.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: cardAspectRatio,
                        ),
                        itemCount: visibleData.length,
                        itemBuilder: (context, index) {
                          final example = visibleData[index];
                          return Card(
                            elevation: 22,
                            shadowColor: const Color(0xCC031D18),
                            surfaceTintColor: Colors.white,
                            color: const Color(0xFFFFFCF4),
                            margin: const EdgeInsets.fromLTRB(2, 2, 2, 12),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: const BorderSide(
                                color: Color(0xFF9B8060),
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                widget.engagement.markViewed(example.id);
                                AdsController.instance
                                    .beforeExampleNavigation(() {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder<void>(
                                      transitionDuration:
                                          const Duration(milliseconds: 520),
                                      reverseTransitionDuration:
                                          const Duration(milliseconds: 360),
                                      pageBuilder: (_, animation, __) =>
                                          ExampleDetailScreen(
                                        example: example,
                                        languages: widget.languages,
                                        quran: widget.quran,
                                        translations: widget.translations,
                                      ),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                        final curved = CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        );
                                        return FadeTransition(
                                          opacity: curved,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, .06),
                                              end: Offset.zero,
                                            ).animate(curved),
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                });
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Hero(
                                    tag: 'example-image-${example.id}',
                                    child: _RevealingExampleImage(
                                      imagePath: example.image,
                                    ),
                                  ),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x22000000),
                                          Color(0x33000000),
                                          Color(0xE6000000),
                                        ],
                                        stops: [0, .45, 1],
                                      ),
                                    ),
                                  ),
                                  PositionedDirectional(
                                    top: 8,
                                    start: 8,
                                    child: IconButton.filled(
                                      tooltip: widget.engagement
                                              .isFavorite(example.id)
                                          ? 'Remove from favorites'
                                          : 'Add to favorites',
                                      style: IconButton.styleFrom(
                                        backgroundColor: widget.engagement
                                                .isFavorite(example.id)
                                            ? const Color(0xFFE53935)
                                            : Colors.black54,
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: Colors.black,
                                      ),
                                      icon: Icon(
                                        widget.engagement.isFavorite(example.id)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                      onPressed: () async {
                                        await widget.engagement
                                            .toggleFavorite(example.id);
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF075E50),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black87,
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  PositionedDirectional(
                                    start: 12,
                                    end: 12,
                                    bottom: 14,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Directionality(
                                          textDirection: _containsArabic(
                                            exampleTopic(
                                              example,
                                              widget.languages.appLanguageCode,
                                            ),
                                          )
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                          child: Text(
                                            exampleTopic(
                                              example,
                                              widget.languages.appLanguageCode,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              height: 1.3,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Chapter ${example.range.surah} • Ayah ${example.range.label}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _RevealingExampleImage extends StatefulWidget {
  const _RevealingExampleImage({required this.imagePath});

  final String imagePath;

  @override
  State<_RevealingExampleImage> createState() => _RevealingExampleImageState();
}

class _RevealingExampleImageState extends State<_RevealingExampleImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _imageOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, .65, curve: Curves.easeOut),
  );
  bool _revealStarted = false;

  void _startReveal() {
    if (_revealStarted) return;
    _revealStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _imageOpacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Transform.scale(
                    scale: 1.18,
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                ColoredBox(color: Colors.black.withValues(alpha: .12)),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    widget.imagePath,
                    fit: BoxFit.contain,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded || frame != null) {
                        _startReveal();
                      }
                      return child;
                    },
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = Curves.easeInOut.transform(_controller.value);
                final glowOpacity =
                    (1 - (progress - .5).abs() * 2).clamp(0.0, 1.0);
                return FractionalTranslation(
                  translation: Offset(-1.4 + (progress * 2.8), 0),
                  child: Opacity(
                    opacity: glowOpacity * .7,
                    child: Transform.rotate(
                      angle: -.18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: .65),
                              Colors.white.withValues(alpha: 0),
                            ],
                            stops: const [0, .5, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
}
