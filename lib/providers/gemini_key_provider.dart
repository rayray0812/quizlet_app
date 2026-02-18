import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'settings';
const _geminiKeyKey = 'gemini_api_key';

class GeminiKeyNotifier extends StateNotifier<String> {
  final FlutterSecureStorage _secureStorage;

  GeminiKeyNotifier({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      super('') {
    _load();
  }

  Future<void> _load() async {
    try {
      final secureValue = (await _secureStorage.read(key: _geminiKeyKey) ?? '')
          .trim();
      if (secureValue.isNotEmpty) {
        state = secureValue;
        return;
      }
    } catch (e) {
      debugPrint('Secure storage read failed: $e');
    }

    // One-time migration from legacy Hive storage.
    try {
      final box = Hive.box(_boxName);
      final legacy = (box.get(_geminiKeyKey, defaultValue: '') as String).trim();
      if (legacy.isNotEmpty) {
        await _secureStorage.write(key: _geminiKeyKey, value: legacy);
        await box.delete(_geminiKeyKey);
        state = legacy;
        return;
      }
      state = '';
    } catch (e) {
      debugPrint('Gemini key migration failed: $e');
      state = '';
    }
  }

  Future<void> setApiKey(String key) async {
    final value = key.trim();
    state = value;
    try {
      if (value.isEmpty) {
        await _secureStorage.delete(key: _geminiKeyKey);
      } else {
        await _secureStorage.write(key: _geminiKeyKey, value: value);
      }
    } catch (e) {
      debugPrint('Secure storage write failed: $e');
    }

    // Clean up legacy slot if it still exists.
    try {
      final box = Hive.box(_boxName);
      if (box.containsKey(_geminiKeyKey)) {
        await box.delete(_geminiKeyKey);
      }
    } catch (e) {
      debugPrint('Legacy key cleanup failed: $e');
    }
  }
}

final geminiKeyProvider = StateNotifierProvider<GeminiKeyNotifier, String>(
  (ref) => GeminiKeyNotifier(),
);
