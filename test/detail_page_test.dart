import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/pages/detail_page.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/services/recipe_service.dart';

void main() {
  testWidgets('renders cooking instructions in the sliver scroll view', (
    tester,
  ) async {
    final service = RecipeService(
      client: MockClient((request) async => http.Response('', 500)),
    );
    addTearDown(service.close);

    const recipe = Recipe(
      id: 1,
      name: 'Resep uji',
      cuisine: 'Indonesia',
      difficulty: 'Mudah',
      prepTimeMinutes: 5,
      cookTimeMinutes: 10,
      servings: 2,
      caloriesPerServing: 100,
      rating: 4.5,
      image: 'https://example.com/recipe.jpg',
      ingredients: ['Bahan uji'],
      instructions: ['Langkah uji'],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FavoriteProvider()),
          Provider<RecipeService>.value(value: service),
        ],
        child: const MaterialApp(home: DetailPage(recipe: recipe)),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Langkah'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Langkah uji'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Langkah uji'), findsOneWidget);
  });
}
