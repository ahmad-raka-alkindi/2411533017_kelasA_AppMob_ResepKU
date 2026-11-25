import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/services/recipe_service.dart';

enum _RecipeAction { edit, delete }

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late int _servings; // state lokal: hanya halaman ini yang butuh
  Recipe? _updatedRecipe;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings; // nilai awal dari data resep
  }

  void _addServing() {
    setState(() => _servings++);
  }

  void _removeServing() {
    if (_servings > 1) {
      setState(() => _servings--);
    }
  }

  Future<void> _editRecipe() async {
    final recipe = _updatedRecipe ?? widget.recipe;
    final controller = TextEditingController(text: recipe.name);
    String? validationError;

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah nama resep'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nama resep',
              errorText: validationError,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => validationError = 'Nama wajib diisi');
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (newName == null || !mounted) return;

    try {
      final updated = await context.read<RecipeService>().updateRecipe(
        id: recipe.id,
        name: newName,
      );
      if (!mounted) return;
      setState(() => _updatedRecipe = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama resep diperbarui menjadi "${updated.name}".'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengubah resep: $error')));
    }
  }

  Future<void> _deleteRecipe() async {
    final recipe = _updatedRecipe ?? widget.recipe;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus resep?'),
        content: Text('Hapus "${recipe.name}" dari server?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final isDeleted = await context.read<RecipeService>().deleteRecipe(
        recipe.id,
      );
      if (!mounted) return;
      if (!isDeleted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Server tidak menghapus resep.')),
        );
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${recipe.name} dihapus dari server.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus resep: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _updatedRecipe ?? widget.recipe;
    final totalCalories = recipe.caloriesPerServing * _servings;
    final isFavorite = context.watch<FavoriteProvider>().isFavorite(recipe);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            title: Text(recipe.name),
            actions: [
              IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () =>
                    context.read<FavoriteProvider>().toggle(recipe),
              ),
              PopupMenuButton<_RecipeAction>(
                tooltip: 'Aksi resep',
                onSelected: (action) {
                  if (action == _RecipeAction.edit) {
                    _editRecipe();
                  } else {
                    _deleteRecipe();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _RecipeAction.edit,
                    child: Text('Ubah nama'),
                  ),
                  PopupMenuItem(
                    value: _RecipeAction.delete,
                    child: Text('Hapus resep'),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: recipe.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.restaurant_menu)),
                    ),
                    errorWidget: (context, url, error) => ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.restaurant_menu)),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  '${recipe.cuisine} • ${recipe.difficulty} • ${recipe.totalTimeMinutes} menit',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text('Porsi', style: textTheme.titleMedium),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: _servings > 1 ? _removeServing : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$_servings',
                            style: textTheme.titleLarge,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _addServing,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total kalori: $totalCalories kkal',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Text('Bahan', style: textTheme.titleLarge),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(recipe.ingredients[index]),
                ),
                childCount: recipe.ingredients.length,
              ),
            ),
          ),
          if (recipe.instructions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Langkah', style: textTheme.titleLarge),
              ),
            ),
          if (recipe.instructions.isNotEmpty)
            SliverList.builder(
              itemCount: recipe.instructions.length,
              itemBuilder: (context, index) => ListTile(
                dense: true,
                leading: CircleAvatar(radius: 12, child: Text('${index + 1}')),
                title: Text(recipe.instructions[index]),
              ),
            ),
          if (recipe.instructions.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
