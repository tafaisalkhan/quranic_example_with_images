import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/content/asset_repositories.dart';
import 'core/language/app_language.dart';
import 'core/engagement/engagement_controller.dart';
import 'core/settings/language_controller.dart';
import 'features/home/presentation/home_menu_screen.dart';
import 'l10n/generated/app_localizations.dart';

class QuranExamplesApp extends StatelessWidget {
  const QuranExamplesApp(
      {super.key, required this.languages, required this.engagement});
  final LanguageController languages;
  final EngagementController engagement;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: languages,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(languages.fontScale),
            ),
            child: child!,
          ),
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: languages.appLanguage.locale,
          supportedLocales: AppLanguages.uiSupported.map((e) => e.locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff0f6959),
                brightness: Brightness.light),
            useMaterial3: true,
            cardTheme:
                const CardThemeData(clipBehavior: Clip.antiAlias, elevation: 0),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff55c9a9),
                brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: HomeMenuScreen(
            languages: languages,
            engagement: engagement,
            examples: AssetExampleRepository(),
            quran: AssetQuranRepository(),
            translations: AssetQuranTranslationRepository(),
          ),
        ),
      );
}
