import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_manager.dart';
import 'screens/main_menu.dart';
import 'state/profile_store.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsStore(prefs);
  await settings.load();
  final profile = ProfileStore(prefs);
  await profile.load();
  await AudioManager.instance.init(settings);
  runApp(DarahApp(settings: settings, profile: profile));
}

class DarahApp extends StatelessWidget {
  const DarahApp({super.key, required this.settings, required this.profile});
  final SettingsStore settings;
  final ProfileStore profile;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFB78C4B);
    final base = ThemeData.dark();
    final body = GoogleFonts.soraTextTheme(base.textTheme);
    final display = GoogleFonts.cinzelTextTheme(base.textTheme);
    final textTheme = body.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
    );

    return MaterialApp(
      title: 'Darah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
        useMaterial3: true,
        textTheme: textTheme,
        scaffoldBackgroundColor: const Color(0xFF0E0C0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF15110E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: MainMenu(settings: settings, profile: profile),
    );
  }
}
