import 'package:flutter/material.dart';

import '../ai/ai_config.dart';
import '../audio/audio_manager.dart';
import '../skins/skins.dart';
import '../state/profile_store.dart';
import '../state/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings, required this.profile});
  final SettingsStore settings;
  final ProfileStore profile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int boardSize;
  late bool vsAi;
  late int aiLevel;
  late bool playerIsP1;
  late bool soundOn;
  late bool musicOn;
  late bool hapticsOn;
  late String boardSkinId;
  late String seedSkinId;
  late String aiTierId;

  @override
  void initState() {
    super.initState();
    boardSize = widget.settings.boardSize;
    vsAi = widget.settings.vsAi;
    aiLevel = widget.settings.aiLevel;
    playerIsP1 = widget.settings.playerIsP1;
    soundOn = widget.settings.soundOn;
    musicOn = widget.settings.musicOn;
    hapticsOn = widget.settings.hapticsOn;
    boardSkinId = widget.profile.equippedBoard;
    seedSkinId = widget.profile.equippedSeed;
    aiTierId = widget.settings.aiTier;
  }

  Future<void> _save() async {
    widget.settings.boardSize = boardSize;
    widget.settings.vsAi = vsAi;
    widget.settings.aiLevel = aiLevel;
    widget.settings.playerIsP1 = playerIsP1;
    widget.settings.soundOn = soundOn;
    widget.settings.musicOn = musicOn;
    widget.settings.hapticsOn = hapticsOn;
    widget.settings.aiTier = aiTierId;
    await widget.settings.save();

    widget.profile.equippedBoard = boardSkinId;
    widget.profile.equippedSeed = seedSkinId;
    await widget.profile.save();

    await AudioManager.instance.sync(widget.settings);
  }

  @override
  Widget build(BuildContext context) {
    final unlockedBoards = boardSkins.where((s) => widget.profile.unlockedBoards.contains(s.id)).toList();
    final unlockedSeeds = seedSkins.where((s) => widget.profile.unlockedSeeds.contains(s.id)).toList();
    final tiers = AiTier.values;

    if (unlockedBoards.isNotEmpty && !unlockedBoards.any((b) => b.id == boardSkinId)) {
      boardSkinId = unlockedBoards.first.id;
    }
    if (unlockedSeeds.isNotEmpty && !unlockedSeeds.any((s) => s.id == seedSkinId)) {
      seedSkinId = unlockedSeeds.first.id;
    }
    if (!widget.profile.unlockedAiTiers.contains(aiTierId)) {
      aiTierId = 'amateur';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: () async {
              await _save();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: 'Board Size',
            child: DropdownButtonFormField<int>(
              value: boardSize,
              items: const [
                DropdownMenuItem(value: 5, child: Text('5x5 (6 seeds/player)')),
                DropdownMenuItem(value: 6, child: Text('6x6 (12 seeds/player)')),
              ],
              onChanged: (v) => setState(() => boardSize = v ?? 5),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Opponent',
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: vsAi,
                  onChanged: (v) => setState(() => vsAi = v),
                  title: const Text('Play vs AI'),
                  subtitle: const Text('Turn off for local pass-and-play'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Choose Player Color'),
                  subtitle: Text(playerIsP1 ? 'You: White (First)' : 'You: Black (Second)'),
                  trailing: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('White')),
                      ButtonSegment(value: false, label: Text('Black')),
                    ],
                    selected: {playerIsP1},
                    onSelectionChanged: (s) => setState(() => playerIsP1 = s.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'AI Difficulty',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tiers.map((tier) {
                    final unlocked = widget.profile.unlockedAiTiers.contains(tier.id);
                    return ChoiceChip(
                      label: Text(tier.label),
                      selected: aiTierId == tier.id,
                      onSelected: unlocked
                          ? (v) => setState(() => aiTierId = tier.id)
                          : null,
                      avatar: unlocked ? null : const Icon(Icons.lock, size: 16),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Level: $aiLevel', style: const TextStyle(fontWeight: FontWeight.w700)),
                Slider(
                  value: aiLevel.toDouble(),
                  min: 1,
                  max: 300,
                  divisions: 299,
                  label: '$aiLevel',
                  onChanged: vsAi ? (v) => setState(() => aiLevel = v.round()) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Audio & Haptics',
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: soundOn,
                  onChanged: (v) => setState(() => soundOn = v),
                  title: const Text('Sound Effects'),
                ),
                SwitchListTile.adaptive(
                  value: musicOn,
                  onChanged: (v) => setState(() => musicOn = v),
                  title: const Text('Background Music'),
                ),
                SwitchListTile.adaptive(
                  value: hapticsOn,
                  onChanged: (v) => setState(() => hapticsOn = v),
                  title: const Text('Haptic Feedback'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Cosmetics',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: boardSkinId,
                  items: unlockedBoards
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setState(() => boardSkinId = v ?? boardSkinId),
                  decoration: const InputDecoration(labelText: 'Board Skin'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: seedSkinId,
                  items: unlockedSeeds
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setState(() => seedSkinId = v ?? seedSkinId),
                  decoration: const InputDecoration(labelText: 'Seed Skin'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await _save();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
