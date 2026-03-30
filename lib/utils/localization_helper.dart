// Helper file to create localized widget builders
// This pattern helps create clean, localized UIs throughout the app

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

// Extension to easily access localization in any widget
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
