import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class DataManager extends ChangeNotifier {
  static const String keyCoins = 'dara_coins';
  static const String keyUnlockedLevels = 'dara_levels';
  static const String keySelectedSeed = 'dara_seed_skin';
  
  int _coins = 0;
  int _unlockedLevels = 1;
  String _selectedSeedColor = 'classic';

  int get coins => _coins;
  int get unlockedLevels => _unlockedLevels;
  String get selectedSeedColor => _selectedSeedColor;

  DataManager() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(keyCoins) ?? 0;
    _unlockedLevels = prefs.getInt(keyUnlockedLevels) ?? 1;
    _selectedSeedColor = prefs.getString(keySelectedSeed) ?? 'classic';
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyCoins, _coins);
    notifyListeners();
  }

  Future<void> unlockNextLevel(int currentLevel) async {
    if (currentLevel >= _unlockedLevels) {
      _unlockedLevels = currentLevel + 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyUnlockedLevels, _unlockedLevels);
      notifyListeners();
    }
  }

  Future<void> setSeedSkin(String skinId) async {
    _selectedSeedColor = skinId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySelectedSeed, skinId);
    notifyListeners();
  }
}
