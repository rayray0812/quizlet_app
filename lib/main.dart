import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quizlet_app/app.dart';
import 'package:quizlet_app/core/constants/app_constants.dart';
import 'package:quizlet_app/core/constants/supabase_constants.dart';
import 'package:quizlet_app/models/adapters/study_set_adapter.dart';
import 'package:quizlet_app/models/adapters/flashcard_adapter.dart';
import 'package:quizlet_app/models/adapters/card_progress_adapter.dart';
import 'package:quizlet_app/models/adapters/review_log_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(StudySetAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(CardProgressAdapter());
  Hive.registerAdapter(ReviewLogAdapter());
  await Hive.openBox(AppConstants.hiveStudySetsBox);
  await Hive.openBox(AppConstants.hiveCardProgressBox);
  await Hive.openBox(AppConstants.hiveReviewLogsBox);
  await Hive.openBox('settings');

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: QuizletApp()));
}
