import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resepku/data/favorite_database.dart';
import 'package:resepku/pages/home_page.dart';
import 'package:resepku/providers/favorite_provider.dart';
import 'package:resepku/providers/settings_provider.dart';
import 'package:resepku/services/recipe_service.dart';
import 'package:resepku/widgets/identity_footer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  final favorites = FavoriteProvider(FavoriteDatabase());
  await Future.wait([settings.load(), favorites.load()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: favorites),
        Provider(
          create: (context) => RecipeService(),
          dispose: (context, service) => service.close(),
        ),
      ],
      child: const ResepKuApp(),
    ),
  );
}

class ResepKuApp extends StatelessWidget {
  const ResepKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResepKu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        fontFamily: 'Poppins', // didaftarkan di pubspec.yaml
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
      ),
      themeMode: context.watch<SettingsProvider>().themeMode,
      builder: (context, child) =>
          IdentityFooter(child: child!), // footer NIM & nama (Modul 6)
      home: const HomePage(),
    );
  }
}
