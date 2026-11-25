import 'package:resepku/data/favorite_database.dart';
import 'package:resepku/models/favorite.dart';
import 'package:resepku/models/recipe.dart';

class MemoryFavoriteStore implements FavoriteStore {
  MemoryFavoriteStore([List<Favorite> initial = const []])
    : _rows = [...initial];

  final List<Favorite> _rows;

  @override
  Future<List<Favorite>> getAll() async {
    return [..._rows]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  @override
  Future<void> insert(Favorite favorite) async {
    _rows.removeWhere((item) => item.recipe.id == favorite.recipe.id);
    _rows.add(favorite);
  }

  @override
  Future<void> updateNote(int id, String note) async {
    final index = _rows.indexWhere((item) => item.recipe.id == id);
    if (index >= 0) _rows[index] = _rows[index].copyWith(note: note);
  }

  @override
  Future<void> incrementCooked(int id) async {
    final index = _rows.indexWhere((item) => item.recipe.id == id);
    if (index >= 0) {
      _rows[index] = _rows[index].copyWith(
        cookedCount: _rows[index].cookedCount + 1,
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    _rows.removeWhere((item) => item.recipe.id == id);
  }

  @override
  Future<void> deleteAll() async => _rows.clear();
}

Favorite sampleFavorite({String note = '', int cookedCount = 0}) {
  const json = {
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
  };
  return Favorite(
    recipe: Recipe.fromJson(json),
    savedAt: DateTime(2026, 10, 1),
    note: note,
    cookedCount: cookedCount,
  );
}
