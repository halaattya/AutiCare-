import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggle() {
    setLocale(_locale.languageCode == 'en' ? const Locale('ar') : const Locale('en'));
  }

  bool get isArabic => _locale.languageCode == 'ar';
}

// ✅ Global controller used across the app (safe + simple)
final LocaleController localeController = LocaleController();
