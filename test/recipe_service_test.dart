import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';

Map<String, dynamic> recipeJson({
  int id = 1,
  String name = 'Resep',
  double rating = 4.5,
}) {
  return {
    'id': id,
    'name': name,
    'rating': rating,
    'ingredients': <String>[],
    'instructions': <String>[],
  };
}

void main() {
  group('Recipe.fromJson', () {
    test('converts an integer rating to double', () {
      final recipe = Recipe.fromJson({...recipeJson(), 'rating': 5});

      expect(recipe.rating, 5.0);
    });

    test('uses defaults for optional fields', () {
      final recipe = Recipe.fromJson(recipeJson());

      expect(recipe.cuisine, '-');
      expect(recipe.prepTimeMinutes, 0);
      expect(recipe.servings, 1);
      expect(recipe.caloriesPerServing, 0);
      expect(recipe.instructions, isEmpty);
    });
  });

  group('RecipeService', () {
    test('fetches recipes from the list endpoint', () async {
      final service = RecipeService(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/recipes');
          expect(request.url.queryParameters['limit'], '50');
          return http.Response(
            jsonEncode({
              'recipes': [recipeJson()],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final recipes = await service.fetchRecipes();

      expect(recipes, hasLength(1));
      expect(recipes.single.name, 'Resep');
    });

    test('searches with an encoded query', () async {
      final service = RecipeService(
        client: MockClient((request) async {
          expect(request.url.path, '/recipes/search');
          expect(request.url.queryParameters['q'], 'tomato pasta');
          return http.Response(
            jsonEncode({
              'recipes': [recipeJson(name: 'Tomato Pasta')],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final recipes = await service.searchRecipes('tomato pasta');

      expect(recipes.single.name, 'Tomato Pasta');
    });

    test('posts a new recipe and parses the server response', () async {
      final service = RecipeService(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/recipes/add');
          expect(jsonDecode(request.body), {
            'name': 'Sambal',
            'cuisine': 'Indonesian',
            'cookTimeMinutes': 30,
          });
          return http.Response(
            jsonEncode(recipeJson(id: 51, name: 'Sambal')),
            201,
          );
        }),
      );
      addTearDown(service.close);

      final recipe = await service.addRecipe(
        name: 'Sambal',
        cuisine: 'Indonesian',
        cookTimeMinutes: 30,
      );

      expect(recipe.id, 51);
      expect(recipe.name, 'Sambal');
    });

    test('updates a recipe name with PUT', () async {
      final service = RecipeService(
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/recipes/1');
          expect(jsonDecode(request.body), {'name': 'Nama baru'});
          return http.Response(jsonEncode(recipeJson(name: 'Nama baru')), 200);
        }),
      );
      addTearDown(service.close);

      final recipe = await service.updateRecipe(id: 1, name: 'Nama baru');

      expect(recipe.name, 'Nama baru');
    });

    test('returns the deletion result from DELETE', () async {
      final service = RecipeService(
        client: MockClient((request) async {
          expect(request.method, 'DELETE');
          expect(request.url.path, '/recipes/1');
          return http.Response(jsonEncode({'isDeleted': true}), 200);
        }),
      );
      addTearDown(service.close);

      expect(await service.deleteRecipe(1), isTrue);
    });

    test('throws when the server responds with a non-success status', () async {
      final service = RecipeService(
        client: MockClient((request) async => http.Response('Not found', 404)),
      );
      addTearDown(service.close);

      await expectLater(
        service.fetchRecipes(),
        throwsA(isA<RecipeServiceException>()),
      );
    });
  });
}
