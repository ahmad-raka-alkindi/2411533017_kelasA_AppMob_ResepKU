import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:resepku/main.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/providers/settings_provider.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:resepku/widgets/recipe_grid_card.dart';
import 'package:resepku/widgets/recipe_tile.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes.dart';

http.Client okClient() {
  return MockClient(
    (request) async => http.Response(
      jsonEncode({
        'recipes': [
          {
            'id': 1,
            'name': 'Classic Margherita Pizza',
            'cuisine': 'Italian',
            'difficulty': 'Easy',
            'prepTimeMinutes': 20,
            'cookTimeMinutes': 15,
            'servings': 4,
            'caloriesPerServing': 300,
            'rating': 4.6,
            'image': '',
            'ingredients': <String>['Pizza dough', 'Tomato'],
            'instructions': <String>['Bake'],
          },
        ],
      }),
      200,
    ),
  );
}

Widget buildApp(
  http.Client client, {
  MemoryFavoriteStore? store,
  SettingsProvider? settings,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings ?? SettingsProvider()),
      ChangeNotifierProvider(
        create: (context) =>
            FavoriteProvider(store ?? MemoryFavoriteStore())..load(),
      ),
      Provider(create: (context) => RecipeService(client: client)),
    ],
    child: const ResepKuApp(),
  );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('pilihan grid dibaca saat aplikasi dibuka', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          SettingsProvider.keyGrid: true,
        });
    final settings = SettingsProvider();
    await settings.load();

    await tester.pumpWidget(buildApp(okClient(), settings: settings));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeGridCard), findsWidgets);
    expect(find.byType(RecipeTile), findsNothing);
  });

  testWidgets('favorit dan catatan tersimpan tampil saat dibuka', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = MemoryFavoriteStore([
      sampleFavorite(note: 'Tambah keju', cookedCount: 2),
    ]);

    await tester.pumpWidget(buildApp(okClient(), store: store));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Favorit saya'));
    await tester.pumpAndSettle();
    expect(find.text('Classic Margherita Pizza'), findsOneWidget);
    expect(find.textContaining('Tambah keju'), findsOneWidget);
    expect(find.textContaining('Dimasak 2 kali'), findsOneWidget);
  });
}
