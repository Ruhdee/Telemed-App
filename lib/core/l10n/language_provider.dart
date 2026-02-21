import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Language state notifier to manage app locale
class LanguageNotifier extends StateNotifier<Locale> {
  final FlutterSecureStorage _storage;
  static const String _languageKey = 'app_language';

  LanguageNotifier(this._storage) : super(const Locale('en', '')) {
    _loadLanguage();
  }

  /// Load saved language preference
  Future<void> _loadLanguage() async {
    final savedLanguage = await _storage.read(key: _languageKey);
    if (savedLanguage != null) {
      state = Locale(savedLanguage, '');
    }
  }

  /// Change language and persist
  Future<void> changeLanguage(String languageCode) async {
    state = Locale(languageCode, '');
    await _storage.write(key: _languageKey, value: languageCode);
  }

  /// Get current language code
  String get currentLanguage => state.languageCode;
}

/// Provider for language state
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier(const FlutterSecureStorage());
});
