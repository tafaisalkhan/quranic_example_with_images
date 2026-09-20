# Examples in the Quran

An offline-first Flutter architecture for presenting canonical Arabic Quran text beside independently versioned translations.

## Content integrity

The repository intentionally ships without verse or translation text. Add only reviewed, licensed, verified data to `assets/data/quran/verses.json` and `assets/data/translations/<language>.json`. Missing content is shown as unavailable; the app never generates religious text.

Each translation entry records `translator` and `source`. Update `assets/data/content_version.json` whenever content changes.

## Run

Install Flutter, then run:

```sh
flutter pub get
flutter gen-l10n
flutter test
flutter run
```

If platform runner folders are not present in a fresh checkout, generate them once with
`flutter create --platforms=android,ios .`; this does not alter the data or feature architecture.

## Adding content or a language

1. Add reviewed canonical verses once to `assets/data/quran/verses.json`.
2. Add licensed translations to the corresponding language JSON, retaining translator and source attribution.
3. Add metadata and clean artwork (with no generated religious text) to `examples.json` and `assets/images/examples/`.
4. Update `content_version.json` and run the tests.

To add a language, add one centralized `AppLanguage` entry, an ARB UI locale, a translation asset, and its version metadata. Feature widgets discover languages from the registry and require no language-specific branching.
