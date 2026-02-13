import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore(this._prefs);
  final SharedPreferences _prefs;

  int boardSize = 5; // 5 or 6
  bool vsAi = true;
  int aiLevel = 15; // 1..300
  // true => player is White (P1), false => player is Black (P2)
  bool playerIsP1 = true;

  bool soundOn = true;
  bool musicOn = true;
  bool hapticsOn = true;

  String boardSkinId = 'wood_classic';
  String seedSkinId = 'stone_classic';

  String aiTier = 'amateur'; // beginner, amateur, pro, master, grandmaster, impossible

  Future<void> load() async {
    boardSize = _prefs.getInt('boardSize') ?? 5;
    vsAi = _prefs.getBool('vsAi') ?? true;
    aiLevel = _prefs.getInt('aiLevel') ?? 15;
    playerIsP1 = _prefs.getBool('playerIsP1') ?? true;

    soundOn = _prefs.getBool('soundOn') ?? true;
    musicOn = _prefs.getBool('musicOn') ?? true;
    hapticsOn = _prefs.getBool('hapticsOn') ?? true;

    boardSkinId = _prefs.getString('boardSkinId') ?? 'wood_classic';
    seedSkinId = _prefs.getString('seedSkinId') ?? 'stone_classic';

    aiTier = _prefs.getString('aiTier') ?? 'amateur';

    // sanity
    if (boardSize != 5 && boardSize != 6) boardSize = 5;
    if (aiLevel < 1) aiLevel = 1;
    if (aiLevel > 300) aiLevel = 300;
  }

  Future<void> save() async {
    await _prefs.setInt('boardSize', boardSize);
    await _prefs.setBool('vsAi', vsAi);
    await _prefs.setInt('aiLevel', aiLevel);
    await _prefs.setBool('playerIsP1', playerIsP1);

    await _prefs.setBool('soundOn', soundOn);
    await _prefs.setBool('musicOn', musicOn);
    await _prefs.setBool('hapticsOn', hapticsOn);

    await _prefs.setString('boardSkinId', boardSkinId);
    await _prefs.setString('seedSkinId', seedSkinId);

    await _prefs.setString('aiTier', aiTier);
  }
}
