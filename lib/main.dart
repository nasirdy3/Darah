import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logic/data_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataManager()),
      ],
      child: const DaraApp(),
    ),
  );
}

class DaraApp extends StatelessWidget {
  const DaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DARA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D6E63),
          brightness: Brightness.dark,
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
