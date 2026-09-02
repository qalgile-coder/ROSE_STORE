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
          themeMode: ThemeMode.values[_prefs.getInt('themeMode') ?? ThemeMode.dark.index],
          locale: Locale(_prefs.getString('languageCode') ?? 'en'),
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
