import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../language/app_language.dart';

class LanguageController extends ChangeNotifier {
  LanguageController(this._preferences);
  static const _appKey = 'app_language';
  static const _translationKey = 'translation_language';
  static const _fontScaleKey = 'font_scale';
  final SharedPreferences _preferences;

  String _appLanguageCode = 'en';
  String _translationLanguageCode = 'en';
  double _fontScale = 1;

  String get appLanguageCode => _appLanguageCode;
  String get translationLanguageCode => _translationLanguageCode;
  double get fontScale => _fontScale;
  AppLanguage get appLanguage => AppLanguages.byCode(_appLanguageCode);
  AppLanguage get translationLanguage =>
      AppLanguages.byCode(_translationLanguageCode);

  void restore() {
    _appLanguageCode =
        _valid(_preferences.getString(_appKey), allowArabic: true);
    _translationLanguageCode =
        _valid(_preferences.getString(_translationKey), allowArabic: false);
    _fontScale = (_preferences.getDouble(_fontScaleKey) ?? 1).clamp(1, 1.3);
  }

  String _valid(String? code, {required bool allowArabic}) {
    final fallback = 'en';
    if (code == null) return fallback;
    final language = AppLanguages.byCode(code);
    return language.code == code && (allowArabic || language.hasTranslation)
        ? code
        : fallback;
  }

  Future<void> increaseFontScale() async {
    _fontScale = _fontScale >= 1.3 ? 1 : _fontScale + .15;
    notifyListeners();
    await _preferences.setDouble(_fontScaleKey, _fontScale);
  }

  Future<void> setAppLanguage(String code) async {
    _appLanguageCode = _valid(code, allowArabic: true);
    notifyListeners();
    await _preferences.setString(_appKey, _appLanguageCode);
  }

  Future<void> setTranslationLanguage(String code) async {
    _translationLanguageCode = _valid(code, allowArabic: false);
    notifyListeners();
    await _preferences.setString(_translationKey, _translationLanguageCode);
  }
}
