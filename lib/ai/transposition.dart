import '../game/types.dart';

class TranspositionEntry {
  TranspositionEntry({
    required this.depth,
    required this.score,
    required this.flag,
    required this.best,
    required this.age,
  });

  final int depth;
  final int score;
  final int flag; // -1 upper, 0 exact, 1 lower
  final Move? best;
  final int age;
}

class TranspositionTable {
  final Map<int, TranspositionEntry> _table = {};
  int _age = 0;

  TranspositionEntry? get(int key) => _table[key];

  void put(int key, TranspositionEntry entry) {
    final existing = _table[key];
    if (existing == null || entry.depth >= existing.depth) {
      _table[key] = entry;
    }
  }

  void tick() => _age++;

  int get age => _age;

  void prune({int maxAge = 3}) {
    _table.removeWhere((_, entry) => (_age - entry.age) > maxAge);
  }

  void clear() => _table.clear();
}
