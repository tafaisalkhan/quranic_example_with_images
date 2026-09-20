import 'package:flutter/material.dart';
import '../../../core/language/app_language.dart';
import '../../../l10n/generated/app_localizations.dart';

Future<void> showLanguageSheet({
  required BuildContext context,
  required String selectedCode,
  required ValueChanged<String> onSelected,
  bool translationsOnly = true,
}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final languages = translationsOnly
            ? AppLanguages.translations
            : AppLanguages.supported;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .78),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 12),
                  child: Text(
                    translationsOnly
                        ? AppLocalizations.of(context).translationLanguage
                        : AppLocalizations.of(context).appLanguage,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      return ListTile(
                        contentPadding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 24),
                        title: Directionality(
                          textDirection: language.direction,
                          child: Text(language.nativeName,
                              textAlign: TextAlign.start),
                        ),
                        subtitle: language.name == language.nativeName
                            ? null
                            : Text(language.name),
                        trailing: language.code == selectedCode
                            ? const Icon(Icons.check_circle)
                            : null,
                        onTap: () {
                          onSelected(language.code);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
