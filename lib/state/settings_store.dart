import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  int boardSize = 5; // 5 or 6
  bool vsAi = true;
  int aiLevel = 15; // 1..100
  // true => player is White (P1), false => player is Black (P2)
  bool playerIsP1 = true;

  Future<void> load() async {
    boardSize = _prefs.getInt('boardSize') ?? 5;
    vsAi = _prefs.getBool('vsAi') ?? true;
    aiLevel = _prefs.getInt('aiLevel') ?? 15;
    playerIsP1 = _prefs.getBool('playerIsP1') ?? true;
    // sanity
    if (boardSize != 5 && boardSize != 6) boardSize = 5;
    if (aiLevel < 1) aiLevel = 1;
    if (aiLevel > 100) aiLevel = 100;
  }

  Future<void> save() async {
    await _prefs.setInt('boardSize', boardSize);
    await _prefs.setBool('vsAi', vsAi);
    await _prefs.setInt('aiLevel', aiLevel);
    await _prefs.setBool('playerIsP1', playerIsP1);
  }
}
