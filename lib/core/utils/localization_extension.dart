import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Extension on BuildContext for easy access to translations
extension LocalizationExtension on BuildContext {
  /// Get AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Shorthand for translating a key
  String tr(String key) => AppLocalizations.of(this).translate(key);
}
