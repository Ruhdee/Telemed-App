import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Extension to easily access translations from context
extension TranslationHelper on BuildContext {
  String t(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}
