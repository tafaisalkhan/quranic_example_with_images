import 'package:flutter/material.dart';
import '../../../core/content/repositories.dart';
import '../../../core/settings/language_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/share_models.dart';
import '../services/share_service.dart';
import 'screens/share_preview_screen.dart';

Future<void> showShareOptions({
  required BuildContext context,
  required ShareContent content,
  required LanguageController languages,
  required QuranTranslationRepository translations,
  ShareService service = const ShareService(),
}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        Future<void> act(Future<void> Function() action) async {
          Navigator.pop(sheetContext);
          await action();
        }

        return SafeArea(
            child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
                    child: Text(l10n.shareExample,
                        style: Theme.of(sheetContext).textTheme.headlineSmall)),
                ListTile(
                    leading: const Icon(Icons.format_quote),
                    title: Text(l10n.shareAyahTranslation),
                    onTap: () => act(() => service.shareText(content,
                        unavailableLabel: l10n.translationUnavailable))),
                ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(l10n.shareImage),
                    enabled: content.example.image.isNotEmpty,
                    onTap: content.example.image.isEmpty
                        ? null
                        : () => act(() =>
                            service.shareAssetImage(content.example.image))),
                Card(
                    color: Theme.of(sheetContext).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.auto_awesome),
                      title: Text(l10n.createShareCard),
                      subtitle: const Text('Recommended · 1080 × 1920'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SharePreviewScreen(
                                      initialContent: content,
                                      languages: languages,
                                      translations: translations,
                                      shareService: service,
                                    )));
                      },
                    )),
                ListTile(
                    leading: const Icon(Icons.copy),
                    title: Text(l10n.copyText),
                    onTap: () => act(() => service.copyText(content,
                        unavailableLabel: l10n.translationUnavailable))),
              ]),
        ));
      },
    );
