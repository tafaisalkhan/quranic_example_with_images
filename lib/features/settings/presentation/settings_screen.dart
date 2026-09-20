import 'package:flutter/material.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/settings/language_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'language_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.languages});
  final LanguageController languages;

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: const SafeArea(
          top: false,
          child: AdBannerSlot(),
        ),
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(AppLocalizations.of(context).settings),
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([languages, AdsController.instance]),
          builder: (context, _) {
            final l10n = AppLocalizations.of(context);
            final ads = AdsController.instance;
            final purchaseSubtitle = ads.adsRemoved
                ? l10n.adsAlreadyRemoved
                : ads.purchasePending
                    ? 'Waiting for Google Play…'
                    : ads.removeAdsPrice == null
                        ? (ads.purchaseError ?? 'Loading Google Play product…')
                        : 'Remove all ads permanently • ${ads.removeAdsPrice}';
            return ListView(
              padding: const EdgeInsetsDirectional.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(
                      ads.adsRemoved
                          ? Icons.verified_rounded
                          : Icons.block_rounded,
                      color: ads.adsRemoved ? Colors.green : null,
                    ),
                    title: Text(l10n.removeAds),
                    subtitle: Text(purchaseSubtitle),
                    trailing: ads.purchasePending
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : ads.adsRemoved
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(Icons.shopping_cart_checkout),
                    enabled: ads.adsRemoved || ads.canPurchase,
                    onTap: ads.adsRemoved || !ads.canPurchase
                        ? null
                        : () async {
                            final started = await ads.buyRemoveAds();
                            if (!started && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ads.purchaseError ??
                                        'Unable to open Google Play purchase.',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ),
                if (!ads.adsRemoved)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: ads.storeAvailable && !ads.purchasePending
                          ? () => ads.restorePurchases()
                          : null,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore purchase'),
                    ),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.text_increase),
                  title: Text(l10n.increaseFont),
                  subtitle: Text(
                    '${l10n.fontSize}: ${(languages.fontScale * 100).round()}%',
                  ),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: languages.increaseFontScale,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(l10n.setLanguage),
                  subtitle: Text(languages.appLanguage.nativeName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLanguageSheet(
                    context: context,
                    selectedCode: languages.appLanguageCode,
                    translationsOnly: false,
                    onSelected: languages.setAppLanguage,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(l10n.translationLanguage),
                  subtitle: Text(languages.translationLanguage.nativeName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLanguageSheet(
                    context: context,
                    selectedCode: languages.translationLanguageCode,
                    onSelected: languages.setTranslationLanguage,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.back),
                ),
              ],
            );
          },
        ),
      );
}
