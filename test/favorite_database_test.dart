import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:resepku/data/favorite_database.dart';
import 'package:resepku/models/favorite.dart';
import 'package:resepku/models/recipe.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const rendang = Recipe(
  id: 1,
  name: 'Rendang',
  cuisine: 'Indonesian',
  difficulty: 'Hard',
  prepTimeMinutes: 30,
  cookTimeMinutes: 180,
  servings: 6,
  caloriesPerServing: 450,
  rating: 4.9,
  image: '',
  ingredients: ['Daging sapi', 'Santan', 'Cabai'],
  instructions: ['Tumis bumbu.', 'Masak hingga kering.'],
);

const soto = Recipe(
  id: 2,
  name: 'Soto Padang',
  cuisine: 'Indonesian',
  difficulty: 'Medium',
  prepTimeMinutes: 20,
  cookTimeMinutes: 60,
  servings: 4,
  caloriesPerServing: 300,
  rating: 4.7,
  image: '',
  ingredients: ['Daging sapi', 'Bihun'],
);

final favRendang = Favorite(recipe: rendang, savedAt: DateTime(2026, 10, 1));
final favSoto = Favorite(recipe: soto, savedAt: DateTime(2026, 10, 2));

void main() {
  sqfliteFfiInit();

  late FavoriteDatabase db;

  setUp(
    () => db = FavoriteDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    ),
  );
  tearDown(() => db.close());

  test('insert lalu getAll, terbaru di atas', () async {
    await db.insert(favRendang);
    await db.insert(favSoto);

    final all = await db.getAll();
    expect(all.map((item) => item.recipe.name), ['Soto Padang', 'Rendang']);
  });

  test('resep tersimpan utuh', () async {
    await db.insert(favRendang);
    final saved = (await db.getAll()).single;
    expect(saved.recipe.ingredients, rendang.ingredients);
    expect(saved.recipe.instructions, hasLength(2));
  });

  test('insert id yang sama mengganti baris lama', () async {
    await db.insert(favRendang);
    await db.insert(favRendang.copyWith(note: 'versi baru'));

    final all = await db.getAll();
    expect(all, hasLength(1));
    expect(all.single.note, 'versi baru');
  });

  test('updateNote, deleteAll, dan delete', () async {
    await db.insert(favRendang);
    await db.insert(favSoto);
    await db.updateNote(1, 'Kurangi santan');
    expect(
      (await db.getAll()).singleWhere((item) => item.recipe.id == 1).note,
      'Kurangi santan',
    );

    await db.deleteAll();
    expect(await db.getAll(), isEmpty);
  });

  test('incrementCooked menambah hitungan memasak', () async {
    await db.insert(favRendang);

    await db.incrementCooked(1);
    await db.incrementCooked(1);

    expect((await db.getAll()).single.cookedCount, 2);
  });

  test('migrasi versi 1 ke 3 tidak menghapus data', () async {
    final dir = await Directory.systemTemp.createTemp('resepku_test');
    final path = p.join(dir.path, 'lama.db');

    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) => database.execute(
          'CREATE TABLE favorites (id INTEGER PRIMARY KEY, name TEXT NOT NULL, '
          'data TEXT NOT NULL, saved_at INTEGER NOT NULL)',
        ),
      ),
    );
    final row = favRendang.toMap();
    await old.insert('favorites', {
      for (final column in ['id', 'name', 'data', 'saved_at'])
        column: row[column],
    });
    await old.close();

    final upgraded = FavoriteDatabase(factory: databaseFactoryFfi, path: path);
    final all = await upgraded.getAll();
    expect(all.single.recipe.name, 'Rendang');
    expect(all.single.note, '');
    expect(all.single.cookedCount, 0);

    await upgraded.updateNote(1, 'Pedas');
    expect((await upgraded.getAll()).single.note, 'Pedas');
    await upgraded.incrementCooked(1);
    expect((await upgraded.getAll()).single.cookedCount, 1);
    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
