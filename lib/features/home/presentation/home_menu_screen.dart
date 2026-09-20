import 'package:flutter/material.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/content/repositories.dart';
import '../../../core/engagement/engagement_controller.dart';
import '../../../core/settings/language_controller.dart';
import '../../examples/presentation/examples_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({
    super.key,
    required this.languages,
    required this.engagement,
    required this.examples,
    required this.quran,
    required this.translations,
  });

  final LanguageController languages;
  final EngagementController engagement;
  final ExampleRepository examples;
  final QuranRepository quran;
  final QuranTranslationRepository translations;

  void _openExamples(BuildContext context, {bool favoritesOnly = false}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExamplesScreen(
          languages: languages,
          engagement: engagement,
          examples: examples,
          quran: quran,
          translations: translations,
          initialFavoritesOnly: favoritesOnly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const SafeArea(
          top: false,
          child: AdBannerSlot(),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/examples/background.png',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x12000000), Color(0x66042320)],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Quranic Example',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFF4DE),
                        fontFamily: 'sans-serif-black',
                        fontSize: 42,
                        height: 1.05,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Color(0xFF082B5B),
                            offset: Offset(0, 3),
                            blurRadius: 2,
                          ),
                          Shadow(
                            color: Color(0xAA000000),
                            offset: Offset(0, 8),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    _MenuButton(
                      icon: Icons.auto_stories_rounded,
                      label: 'Quranic Examples',
                      onPressed: () => _openExamples(context),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      icon: Icons.favorite_rounded,
                      label: 'Favorites',
                      onPressed: () =>
                          _openExamples(context, favoritesOnly: true),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SettingsScreen(languages: languages),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xB3FFFFFF), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF083B82),
              offset: Offset(0, 7),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, 11),
              blurRadius: 12,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66FFFFFF)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .3,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            offset: Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xDDFFFFFF),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
