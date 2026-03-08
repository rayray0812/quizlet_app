import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Supported AI providers for photo scanning.
enum AiProvider { gemini, groq }

const _boxName = 'settings';
const _providerKey = 'ai_provider';
const _groqKeyKey = 'groq_api_key';

/// Notifier that persists the selected AI provider in Hive settings box.
class AiProviderNotifier extends StateNotifier<AiProvider> {
  AiProviderNotifier() : super(AiProvider.gemini) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box(_boxName);
      final raw = box.get(_providerKey, defaultValue: 'gemini') as String;
      state = raw == 'groq' ? AiProvider.groq : AiProvider.gemini;
    } catch (e) {
      debugPrint('AI provider load failed: $e');
      state = AiProvider.gemini;
    }
  }

  Future<void> setProvider(AiProvider provider) async {
    state = provider;
    try {
      final box = Hive.box(_boxName);
      await box.put(_providerKey, provider.name);
    } catch (e) {
      debugPrint('AI provider save failed: $e');
    }
  }
}

final aiProviderProvider =
    StateNotifierProvider<AiProviderNotifier, AiProvider>(
  (ref) => AiProviderNotifier(),
);

/// Groq API Key stored in FlutterSecureStorage (same pattern as geminiKeyProvider).
class GroqKeyNotifier extends StateNotifier<String> {
  final FlutterSecureStorage _secureStorage;

  GroqKeyNotifier({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      super('') {
    _load();
  }

  Future<void> _load() async {
    try {
      final value = (await _secureStorage.read(key: _groqKeyKey) ?? '').trim();
      state = value;
    } catch (e) {
      debugPrint('Groq key load failed: $e');
      state = '';
    }
  }

  Future<void> setApiKey(String key) async {
    final value = key.trim();
    state = value;
    try {
      if (value.isEmpty) {
        await _secureStorage.delete(key: _groqKeyKey);
      } else {
        await _secureStorage.write(key: _groqKeyKey, value: value);
      }
    } catch (e) {
      debugPrint('Groq key write failed: $e');
    }
  }
}

final groqKeyProvider = StateNotifierProvider<GroqKeyNotifier, String>(
  (ref) => GroqKeyNotifier(),
);
