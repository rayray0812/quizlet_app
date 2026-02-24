import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recall_app/core/constants/app_constants.dart';

enum TtsEngine {
  cloudTts, // Google Cloud TTS (Journey/Wavenet/Neural2)
  geminiTts, // Gemini Flash TTS (token-based)
  deviceTts, // flutter_tts (built-in)
}

class TtsEngineNotifier extends StateNotifier<TtsEngine> {
  TtsEngineNotifier() : super(TtsEngine.cloudTts) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      final raw = box.get(AppConstants.settingTtsEngineKey, defaultValue: 'cloudTts') as String;
      state = TtsEngine.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => TtsEngine.cloudTts,
      );
    } catch (_) {
      state = TtsEngine.cloudTts;
    }
  }

  Future<void> setEngine(TtsEngine engine) async {
    state = engine;
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      await box.put(AppConstants.settingTtsEngineKey, engine.name);
    } catch (_) {}
  }
}

final ttsEngineProvider = StateNotifierProvider<TtsEngineNotifier, TtsEngine>(
  (ref) => TtsEngineNotifier(),
);
