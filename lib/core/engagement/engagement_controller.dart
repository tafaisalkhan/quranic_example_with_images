import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EngagementController extends ChangeNotifier {
  EngagementController._(this._preferences);
  static const _storageKey = 'daily_example_progress';
  final SharedPreferences _preferences;
  final Set<String> _favorites = {};
  final Set<String> _viewed = {};
  String? _dailyExampleId;
  String? _dailyDate;

  Set<String> get favorites => Set.unmodifiable(_favorites);
  bool isFavorite(String id) => _favorites.contains(id);
  String? get dailyExampleId => _dailyExampleId;

  static Future<EngagementController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final controller = EngagementController._(preferences);
    final savedProgress = preferences.getString(_storageKey);
    if (savedProgress != null) {
      try {
        final json = jsonDecode(savedProgress) as Map<String, dynamic>;
        controller._favorites
            .addAll((json['favoriteIds'] as List? ?? const []).cast<String>());
        controller._viewed
            .addAll((json['viewedIds'] as List? ?? const []).cast<String>());
        controller._dailyExampleId = json['dailyExampleId'] as String?;
        controller._dailyDate = json['dailyDate'] as String?;
      } catch (_) {}
    }
    return controller;
  }

  Future<void> prepareDailyExample(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_dailyDate == today && _dailyExampleId != null) return;
    _dailyDate = today;
    _dailyExampleId =
        ids[now.difference(DateTime(now.year, 1, 1)).inDays % ids.length];
    await _save();
    notifyListeners();
  }

  Future<void> markViewed(String id) async {
    if (_viewed.add(id)) await _save();
  }

  Future<void> toggleFavorite(String id) async {
    _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    await _preferences.setString(
        _storageKey,
        jsonEncode({
          'dailyDate': _dailyDate,
          'dailyExampleId': _dailyExampleId,
          'viewedIds': _viewed.toList()..sort(),
          'favoriteIds': _favorites.toList()..sort(),
          'updatedAt': DateTime.now().toIso8601String(),
        }));
  }
}
