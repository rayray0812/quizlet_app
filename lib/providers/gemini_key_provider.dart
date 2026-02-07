import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'settings';
const _geminiKeyKey = 'gemini_api_key';

class GeminiKeyNotifier extends StateNotifier<String> {
  GeminiKeyNotifier() : super('') {
    _load();
  }

  void _load() {
    final box = Hive.box(_boxName);
    state = box.get(_geminiKeyKey, defaultValue: '') as String;
  }

  void setApiKey(String key) {
    state = key.trim();
    final box = Hive.box(_boxName);
    box.put(_geminiKeyKey, state);
  }
}

final geminiKeyProvider = StateNotifierProvider<GeminiKeyNotifier, String>(
  (ref) => GeminiKeyNotifier(),
);
