import 'package:flutter/material.dart';

class BoardSkin {
  const BoardSkin({
    required this.id,
    required this.name,
    required this.baseGradient,
    required this.frame,
    required this.grid,
    required this.pitDark,
    required this.pitLight,
    required this.highlight,
    required this.capture,
  });

  final String id;
  final String name;
  final List<Color> baseGradient;
  final Color frame;
  final Color grid;
  final Color pitDark;
  final Color pitLight;
  final Color highlight;
  final Color capture;
}

class SeedPalette {
  const SeedPalette({required this.base, required this.rim, required this.glow});
  final Color base;
  final Color rim;
  final Color glow;
}

class SeedSkin {
  const SeedSkin({
    required this.id,
    required this.name,
    required this.p1,
    required this.p2,
  });

  final String id;
  final String name;
  final SeedPalette p1;
  final SeedPalette p2;
}

final List<BoardSkin> boardSkins = [
  BoardSkin(
    id: 'wood_classic',
    name: 'Wood Classic',
    baseGradient: [Color(0xFF5A3A28), Color(0xFF3E271B), Color(0xFF2B1C14)],
    frame: Color(0xFF1A120D),
    grid: Color(0xFF0B0A09),
    pitDark: Color(0xFF2A1A12),
    pitLight: Color(0xFF553624),
    highlight: Color(0xFF00E5FF),
    capture: Color(0xFFE53935),
  ),
  BoardSkin(
    id: 'marble_elite',
    name: 'Marble Elite',
    baseGradient: [Color(0xFFF2EEE9), Color(0xFFE2D9D0), Color(0xFFCFC4B9)],
    frame: Color(0xFF8E8277),
    grid: Color(0xFF7A6D63),
    pitDark: Color(0xFFC9BEB3),
    pitLight: Color(0xFFF7F2EC),
    highlight: Color(0xFF2A9DF4),
    capture: Color(0xFFD64545),
  ),
  BoardSkin(
    id: 'ebony_luxury',
    name: 'Ebony Luxury',
    baseGradient: [Color(0xFF1A1A1A), Color(0xFF0E0E0E), Color(0xFF070707)],
    frame: Color(0xFF2E2E2E),
    grid: Color(0xFF1F1F1F),
    pitDark: Color(0xFF101010),
    pitLight: Color(0xFF2B2B2B),
    highlight: Color(0xFFFFD54F),
    capture: Color(0xFFEF5350),
  ),
  BoardSkin(
    id: 'tribal_earth',
    name: 'Tribal Earth',
    baseGradient: [Color(0xFF6C4A2F), Color(0xFF513520), Color(0xFF3A2516)],
    frame: Color(0xFF2C1B10),
    grid: Color(0xFF1B120B),
    pitDark: Color(0xFF3C2518),
    pitLight: Color(0xFF7B5135),
    highlight: Color(0xFF7CFF6B),
    capture: Color(0xFFFF7043),
  ),
  BoardSkin(
    id: 'neon_cyber',
    name: 'Neon Cyber',
    baseGradient: [Color(0xFF0A0D13), Color(0xFF05070B), Color(0xFF020407)],
    frame: Color(0xFF131A26),
    grid: Color(0xFF0D141F),
    pitDark: Color(0xFF0B111A),
    pitLight: Color(0xFF1B2738),
    highlight: Color(0xFF40C4FF),
    capture: Color(0xFFFF5252),
  ),
];

final List<SeedSkin> seedSkins = [
  SeedSkin(
    id: 'stone_classic',
    name: 'Classic Stones',
    p1: SeedPalette(base: Color(0xFFEDE3D1), rim: Color(0xFFBFAF92), glow: Color(0xFF00E5FF)),
    p2: SeedPalette(base: Color(0xFF1A1A1A), rim: Color(0xFF4E4E4E), glow: Color(0xFFFFD54F)),
  ),
  SeedSkin(
    id: 'gold_elite',
    name: 'Gold Elite',
    p1: SeedPalette(base: Color(0xFFFFE08A), rim: Color(0xFFC8A049), glow: Color(0xFFFFC107)),
    p2: SeedPalette(base: Color(0xFF2D2A27), rim: Color(0xFF5B524B), glow: Color(0xFFFF8F00)),
  ),
  SeedSkin(
    id: 'crystal',
    name: 'Crystal',
    p1: SeedPalette(base: Color(0xFFDFF6FF), rim: Color(0xFF9ED9F6), glow: Color(0xFF40C4FF)),
    p2: SeedPalette(base: Color(0xFF1A2B3B), rim: Color(0xFF314B66), glow: Color(0xFF00B0FF)),
  ),
  SeedSkin(
    id: 'obsidian',
    name: 'Obsidian',
    p1: SeedPalette(base: Color(0xFFD1D1D1), rim: Color(0xFF9A9A9A), glow: Color(0xFF90CAF9)),
    p2: SeedPalette(base: Color(0xFF0D0D0D), rim: Color(0xFF2F2F2F), glow: Color(0xFFB0BEC5)),
  ),
  SeedSkin(
    id: 'ember_fire',
    name: 'Ember Fire',
    p1: SeedPalette(base: Color(0xFFFFCC80), rim: Color(0xFFEF9A57), glow: Color(0xFFFF7043)),
    p2: SeedPalette(base: Color(0xFF2A1A16), rim: Color(0xFF5C3B33), glow: Color(0xFFFF8A65)),
  ),
];

BoardSkin boardSkinById(String id) {
  return boardSkins.firstWhere((s) => s.id == id, orElse: () => boardSkins.first);
}

SeedSkin seedSkinById(String id) {
  return seedSkins.firstWhere((s) => s.id == id, orElse: () => seedSkins.first);
}
