import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  String _selectedLanguage = 'hi';
  
  String get selectedLanguage => _selectedLanguage;
  
  void changeLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }
  
  // Helper methods for common text
  String getText(String englishText, String kannadaText, [String? hindiText]) {
    if (_selectedLanguage == 'kn') {
      return kannadaText;
    } else if (_selectedLanguage == 'hi') {
      return hindiText ?? englishText; // Fallback to English if Hindi text not provided
    } else {
      return englishText;
    }
  }
}
