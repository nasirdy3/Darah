import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_menu.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsStore(prefs);
  await settings.load();
  runApp(DarahApp(settings: settings));
}

class DarahApp extends StatelessWidget {
  const DarahApp({super.key, required this.settings});
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final seedColor = const Color(0xFF4E3524);
    return MaterialApp(
      title: 'Darah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: MainMenu(settings: settings),
    );
  }
}
