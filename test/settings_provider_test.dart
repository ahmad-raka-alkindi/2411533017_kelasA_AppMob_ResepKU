import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resepku/providers/settings_provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('pembukaan pertama menggunakan nilai bawaan', () async {
    final settings = SettingsProvider();
    await settings.load();

    expect(settings.isGrid, isFalse);
    expect(settings.isDark, isFalse);
    expect(settings.themeMode, ThemeMode.light);
  });

  test('nilai grid tetap ada setelah dibuka ulang', () async {
    await SettingsProvider().setGrid(true);

    final reopened = SettingsProvider();
    await reopened.load();
    expect(reopened.isGrid, isTrue);
  });

  test('membaca mode gelap yang sudah tersimpan', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          SettingsProvider.keyDark: true,
        });

    final settings = SettingsProvider();
    await settings.load();
    expect(settings.themeMode, ThemeMode.dark);
  });

  test('setDark memberi tahu listener', () async {
    final settings = SettingsProvider();
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setDark(true);
    expect(settings.isDark, isTrue);
    expect(notified, 1);
  });

  test('urutkan favorit disimpan dan dibaca ulang', () async {
    await SettingsProvider().setFavoriteSort(FavoriteSort.name);

    final reopened = SettingsProvider();
    await reopened.load();
    expect(reopened.favoriteSort, FavoriteSort.name);
  });
}
