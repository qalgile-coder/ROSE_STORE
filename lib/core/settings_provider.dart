import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  SettingsState({
    required this.themeMode,
    required this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          // تم تغيير القيمة الافتراضية عند عدم وجود إعداد مخزن مسبقاً لتقع على الوضع النهاري (ThemeMode.light) بدلاً من الداكن
          themeMode: ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.light.index],
          // تم ضبط القيمة الافتراضية للغة لتتوافق مع مشروعك (العربية 'ar' بدلاً من 'en')
          locale: Locale(_prefs.getString('languageCode') ?? 'ar'),
        ));

  void toggleTheme(bool isDark) {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: mode);
    _prefs.setInt('themeMode', mode.index);
  }

  void setLocale(String languageCode) {
    final locale = Locale(languageCode);
    state = state.copyWith(locale: locale);
    _prefs.setString('languageCode', languageCode);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});