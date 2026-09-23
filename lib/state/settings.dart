import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user preferences.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'en',
    this.currency = 'EGP',
  });

  final ThemeMode themeMode;
  final String localeCode;
  final String currency;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    String? currency,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
        currency: currency ?? this.currency,
      );

  static ThemeMode themeModeFrom(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String themeModeTo(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._prefs, AppSettings initial) : super(initial);

  final SharedPreferences _prefs;

  static const _kTheme = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kCurrency = 'currency';

  static AppSettings read(SharedPreferences prefs) => AppSettings(
        themeMode: AppSettings.themeModeFrom(prefs.getString(_kTheme) ?? 'system'),
        localeCode: prefs.getString(_kLocale) ?? 'en',
        currency: prefs.getString(_kCurrency) ?? 'EGP',
      );

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(_kTheme, AppSettings.themeModeTo(mode));
  }

  void setLocale(String code) {
    state = state.copyWith(localeCode: code);
    _prefs.setString(_kLocale, code);
  }

  void setCurrency(String code) {
    state = state.copyWith(currency: code);
    _prefs.setString(_kCurrency, code);
  }
}

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsController(prefs, SettingsController.read(prefs));
});
