import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _locale = const Locale('it'); // Default to Italian
  
  Locale get locale => _locale;
  
  LanguageProvider() {
    _loadLanguage();
  }
  
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'it';
    _locale = Locale(languageCode);
    notifyListeners();
  }
  
  Future<void> setLanguage(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }
  
  // Helper method to get language name
  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'it':
        return 'Italiano';
      case 'bn':
        return 'বাংলা';
      default:
        return 'Unknown';
    }
  }
}
