import '../game/types.dart';

class TranspositionEntry {
  TranspositionEntry({
    required this.depth,
    required this.score,
    required this.flag,
    required this.best,
  });

  final int depth;
  final int score;
  final int flag; // -1 upper, 0 exact, 1 lower
  final Move? best;
}

class TranspositionTable {
  final Map<int, TranspositionEntry> _table = {};

  TranspositionEntry? get(int key) => _table[key];

  void put(int key, TranspositionEntry entry) {
    final existing = _table[key];
    if (existing == null || entry.depth >= existing.depth) {
      _table[key] = entry;
    }
  }

  void clear() => _table.clear();
}
