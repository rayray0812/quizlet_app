import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recall_app/app.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/constants/supabase_constants.dart';
import 'package:recall_app/models/adapters/study_set_adapter.dart';
import 'package:recall_app/models/adapters/flashcard_adapter.dart';
import 'package:recall_app/models/adapters/card_progress_adapter.dart';
import 'package:recall_app/models/adapters/review_log_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(StudySetAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(CardProgressAdapter());
  Hive.registerAdapter(ReviewLogAdapter());
  try {
    await Hive.openBox(AppConstants.hiveStudySetsBox);
    await Hive.openBox(AppConstants.hiveCardProgressBox);
    await Hive.openBox(AppConstants.hiveReviewLogsBox);
    await Hive.openBox(AppConstants.hiveSettingsBox);
  } catch (e) {
    debugPrint('Hive openBox failed: $e');
  }

  // Initialize Supabase (may fail with placeholder credentials ??app still works offline)
  try {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init failed (offline mode): $e');
  }

  runApp(const ProviderScope(child: RecallApp()));
}

