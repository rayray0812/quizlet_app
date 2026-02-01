import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'settings';
const _localeKey = 'locale_language_code';
const _localeCountryKey = 'locale_country_code';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('zh', 'TW')) {
    _load();
  }

  void _load() {
    final box = Hive.box(_boxName);
    final langCode = box.get(_localeKey, defaultValue: 'zh') as String;
    final countryCode = box.get(_localeCountryKey, defaultValue: 'TW') as String;
    state = Locale(langCode, countryCode);
  }

  void setLocale(Locale locale) {
    state = locale;
    final box = Hive.box(_boxName);
    box.put(_localeKey, locale.languageCode);
    box.put(_localeCountryKey, locale.countryCode ?? '');
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
