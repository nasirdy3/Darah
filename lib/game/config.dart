class BoardConfig {
  BoardConfig(this.size);
  final int size;

  int seedsPerPlayer() => size == 5 ? 6 : 12;

  bool inBounds(int r, int c) => r >= 0 && c >= 0 && r < size && c < size;
}
