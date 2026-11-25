import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:resepku/widgets/error_view.dart';
import 'package:resepku/widgets/recipe_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _queryController = TextEditingController();
  Future<List<Recipe>>? _recipesFuture;
  String _lastQuery = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _lastQuery = normalizedQuery;
      _recipesFuture = context.read<RecipeService>().searchRecipes(
        normalizedQuery,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Cari resep...',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            tooltip: 'Cari',
            icon: const Icon(Icons.search),
            onPressed: () => _search(_queryController.text),
          ),
        ],
      ),
      body: _buildResults(),
    );
  }

  Widget _buildResults() {
    final recipesFuture = _recipesFuture;
    if (recipesFuture == null) {
      return const Center(child: Text('Masukkan kata kunci untuk mencari.'));
    }

    return FutureBuilder<List<Recipe>>(
      future: recipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: 'Gagal mencari resep.\n${snapshot.error}',
            onRetry: () => _search(_lastQuery),
          );
        }

        final recipes = snapshot.data ?? [];
        if (recipes.isEmpty) {
          return Center(child: Text('Tidak ada resep untuk "$_lastQuery".'));
        }

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) => RecipeTile(recipe: recipes[index]),
        );
      },
    );
  }
}
