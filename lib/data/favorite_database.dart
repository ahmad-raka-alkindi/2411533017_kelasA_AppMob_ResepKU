import 'package:path/path.dart' as p;
import 'package:resepku/models/favorite.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class FavoriteStore {
  Future<List<Favorite>> getAll();
  Future<void> insert(Favorite favorite);
  Future<void> updateNote(int id, String note);
  Future<void> incrementCooked(int id);
  Future<void> delete(int id);
  Future<void> deleteAll();
}

class FavoriteDatabase implements FavoriteStore {
  FavoriteDatabase({DatabaseFactory? factory, this.path})
    : _factory = factory ?? databaseFactorySqflitePlugin;

  static const _table = 'favorites';
  static const _version = 3;

  final DatabaseFactory _factory;
  final String? path;
  Database? _db;

  Future<Database> get _database async => _db ??= await _open();

  Future<Database> _open() async {
    final dbPath =
        path ?? p.join(await _factory.getDatabasesPath(), 'resepku.db');
    return _factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        data TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        cooked_count INTEGER NOT NULL DEFAULT 0,
        saved_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $_table ADD COLUMN note TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE $_table ADD COLUMN cooked_count INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  @override
  Future<List<Favorite>> getAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'saved_at DESC');
    return rows.map(Favorite.fromMap).toList();
  }

  @override
  Future<void> insert(Favorite favorite) async {
    final db = await _database;
    await db.insert(
      _table,
      favorite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateNote(int id, String note) async {
    final db = await _database;
    await db.update(_table, {'note': note}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> incrementCooked(int id) async {
    final db = await _database;
    await db.rawUpdate(
      'UPDATE $_table SET cooked_count = cooked_count + 1 WHERE id = ?',
      [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_table);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
