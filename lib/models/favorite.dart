import 'dart:convert';

import 'package:resepku/models/recipe.dart';

class Favorite {
  const Favorite({
    required this.recipe,
    required this.savedAt,
    this.note = '',
    this.cookedCount = 0,
  });

  final Recipe recipe;
  final DateTime savedAt;
  final String note;
  final int cookedCount;

  Favorite copyWith({String? note, int? cookedCount}) {
    return Favorite(
      recipe: recipe,
      savedAt: savedAt,
      note: note ?? this.note,
      cookedCount: cookedCount ?? this.cookedCount,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': recipe.id,
      'name': recipe.name,
      'data': jsonEncode(recipe.toJson()),
      'note': note,
      'cooked_count': cookedCount,
      'saved_at': savedAt.millisecondsSinceEpoch,
    };
  }

  factory Favorite.fromMap(Map<String, Object?> map) {
    final json = jsonDecode(map['data'] as String);
    return Favorite(
      recipe: Recipe.fromJson(json as Map<String, dynamic>),
      savedAt: DateTime.fromMillisecondsSinceEpoch(map['saved_at'] as int),
      note: map['note'] as String? ?? '',
      cookedCount: map['cooked_count'] as int? ?? 0,
    );
  }
}
