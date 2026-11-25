import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:resepku/data/favorite_database.dart';
import 'package:resepku/models/favorite.dart';
import 'package:resepku/models/recipe.dart';

class _MemoryFavoriteStore implements FavoriteStore {
  final List<Favorite> _items = [];

  @override
  Future<List<Favorite>> getAll() async =>
      [..._items]..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Future<void> insert(Favorite favorite) async {
    _items.removeWhere((item) => item.recipe.id == favorite.recipe.id);
    _items.add(favorite);
  }

  @override
  Future<void> updateNote(int id, String note) async {
    final index = _items.indexWhere((item) => item.recipe.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(note: note);
  }

  @override
  Future<void> incrementCooked(int id) async {
    final index = _items.indexWhere((item) => item.recipe.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        cookedCount: _items[index].cookedCount + 1,
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((item) => item.recipe.id == id);
  }

  @override
  Future<void> deleteAll() async => _items.clear();
}

class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider([FavoriteStore? store])
    : _store = store ?? _MemoryFavoriteStore();

  final FavoriteStore _store;
  List<Favorite> _items = [];

  UnmodifiableListView<Favorite> get items => UnmodifiableListView(_items);
  int get count => _items.length;

  bool isFavorite(Recipe recipe) =>
      _items.any((item) => item.recipe.id == recipe.id);

  Future<void> load() async {
    _items = await _store.getAll();
    notifyListeners();
  }

  Future<void> toggle(Recipe recipe) async {
    if (isFavorite(recipe)) {
      _items.removeWhere((item) => item.recipe.id == recipe.id);
      notifyListeners();
      await _store.delete(recipe.id);
    } else {
      final favorite = Favorite(recipe: recipe, savedAt: DateTime.now());
      _items.insert(0, favorite);
      notifyListeners();
      await _store.insert(favorite);
    }
  }

  Future<void> updateNote(int id, String note) async {
    final index = _items.indexWhere((item) => item.recipe.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(note: note);
    notifyListeners();
    await _store.updateNote(id, note);
  }

  Future<void> incrementCooked(int id) async {
    final index = _items.indexWhere((item) => item.recipe.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      cookedCount: _items[index].cookedCount + 1,
    );
    notifyListeners();
    await _store.incrementCooked(id);
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _store.deleteAll();
  }
}
