import 'package:flutter/material.dart';

/// App-level locale override. `null` follows the system locale.
class LocaleController extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale? locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void useSystem() => setLocale(null);

  void useEnglish() => setLocale(const Locale('en'));

  void useChinese() => setLocale(const Locale('zh'));
}
