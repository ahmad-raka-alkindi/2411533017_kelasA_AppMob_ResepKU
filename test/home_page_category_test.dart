import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:resepku/pages/home_page.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/providers/settings_provider.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Map<String, dynamic> recipeJson({
  required int id,
  required String name,
  required String cuisine,
}) {
  return {
    'id': id,
    'name': name,
    'cuisine': cuisine,
    'difficulty': 'Easy',
    'prepTimeMinutes': 10,
    'cookTimeMinutes': 20,
    'servings': 2,
    'caloriesPerServing': 300,
    'rating': 4.5,
    'image': 'https://example.com/$id.jpg',
    'ingredients': <String>[],
    'instructions': <String>[],
  };
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('filters recipes by cuisine and shows all by default', (
    tester,
  ) async {
    final service = RecipeService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'recipes': [
              recipeJson(id: 1, name: 'Pasta Italia', cuisine: 'Italian'),
              recipeJson(id: 2, name: 'Tumis Asia', cuisine: 'Asian'),
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(service.close);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FavoriteProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          Provider<RecipeService>.value(value: service),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Italian'), findsOneWidget);
    expect(find.text('Asian'), findsOneWidget);
    expect(find.text('Pasta Italia'), findsOneWidget);
    expect(find.text('Tumis Asia'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Italian'));
    await tester.pumpAndSettle();

    expect(find.text('Pasta Italia'), findsOneWidget);
    expect(find.text('Tumis Asia'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
    await tester.pumpAndSettle();

    expect(find.text('Pasta Italia'), findsOneWidget);
    expect(find.text('Tumis Asia'), findsOneWidget);
  });
}
