import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FavoriteSort { newest, name }

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const keyGrid = 'is_grid';
  static const keyDark = 'is_dark';
  static const keyFavoriteSort = 'favorite_sort';

  final SharedPreferencesAsync _prefs;
  bool _isGrid = false;
  bool _isDark = false;
  FavoriteSort _favoriteSort = FavoriteSort.newest;

  bool get isGrid => _isGrid;
  bool get isDark => _isDark;
  FavoriteSort get favoriteSort => _favoriteSort;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _isGrid = await _prefs.getBool(keyGrid) ?? false;
    _isDark = await _prefs.getBool(keyDark) ?? false;
    final sortName = await _prefs.getString(keyFavoriteSort);
    _favoriteSort =
        FavoriteSort.values.asNameMap()[sortName] ?? FavoriteSort.newest;
    notifyListeners();
  }

  Future<void> setGrid(bool value) async {
    _isGrid = value;
    notifyListeners();
    await _prefs.setBool(keyGrid, value);
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    notifyListeners();
    await _prefs.setBool(keyDark, value);
  }

  Future<void> setFavoriteSort(FavoriteSort value) async {
    _favoriteSort = value;
    notifyListeners();
    await _prefs.setString(keyFavoriteSort, value.name);
  }
}
