import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/engagement/daily_reminder_service.dart';
import 'core/engagement/engagement_controller.dart';
import 'core/settings/language_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final languages = LanguageController(preferences)..restore();
  final engagement = await EngagementController.load();
  runApp(QuranExamplesApp(languages: languages, engagement: engagement));
  unawaited(DailyReminderService.initialize());
  unawaited(AdsController.instance.initialize());
}
