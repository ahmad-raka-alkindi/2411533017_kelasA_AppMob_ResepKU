import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/models/recipe.dart';
import 'package:resepku/services/recipe_service.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final service = context.read<RecipeService>();
    setState(() => _saving = true);

    try {
      final created = await service.addRecipe(
        name: _nameController.text.trim(),
        cuisine: _cuisineController.text.trim(),
        cookTimeMinutes: int.parse(_minutesController.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop<Recipe>(created);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim resep: $error')));
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  String? _validateMinutes(String? value) {
    final minutes = int.tryParse(value?.trim() ?? '');
    if (minutes == null || minutes <= 0) {
      return 'Isi dengan angka lebih dari 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Resep')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama resep'),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cuisineController,
              decoration: const InputDecoration(
                labelText: 'Cuisine, misalnya Indonesian',
              ),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minutesController,
              decoration: const InputDecoration(
                labelText: 'Waktu memasak (menit)',
              ),
              keyboardType: TextInputType.number,
              validator: _validateMinutes,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Mengirim...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
