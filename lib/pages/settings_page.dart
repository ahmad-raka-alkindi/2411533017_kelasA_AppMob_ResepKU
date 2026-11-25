import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus semua favorit?'),
        content: const Text('Semua resep favorit akan dihapus dari perangkat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus semua'),
          ),
        ],
      ),
    );
    if (shouldClear != true || !context.mounted) return;
    await context.read<FavoriteProvider>().clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua favorit berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final favoriteCount = context.watch<FavoriteProvider>().count;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode gelap'),
            value: settings.isDark,
            onChanged: settings.setDark,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.grid_view),
            title: const Text('Tampilan grid'),
            subtitle: const Text('Daftar resep ditampilkan dalam dua kolom'),
            value: settings.isGrid,
            onChanged: settings.setGrid,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Hapus semua favorit'),
            subtitle: Text('$favoriteCount resep tersimpan'),
            enabled: favoriteCount > 0,
            onTap: () => _confirmDeleteAll(context),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Pengaturan tersimpan di HP'),
            subtitle: Text('Pilihan tetap ada walaupun aplikasi ditutup.'),
          ),
        ],
      ),
    );
  }
}
