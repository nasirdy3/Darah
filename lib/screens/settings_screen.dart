import 'dart:ui';
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
            backgroundColor: const Color(0xFF0F0F0F),
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () async {
                  await _save();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4DD0E1))),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(title: 'Game Config'),
                _GlassCard(
                  child: Column(
                    children: [
                      _SettingRow(
                        title: 'Board Size',
                        subtitle: boardSize == 5 ? '5x5 (Standard)' : '6x6 (Pro)',
                        trailing: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 5, label: Text('5x5')),
                            ButtonSegment(value: 6, label: Text('6x6')),
                          ],
                          selected: {boardSize},
                          onSelectionChanged: (s) => setState(() => boardSize = s.first),
                        ),
                      ),
                      const _Divider(),
                      _SettingRow(
                        title: 'Player Color',
                        subtitle: playerIsP1 ? 'Start first as White' : 'Start second as Black',
                        trailing: SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('White')),
                            ButtonSegment(value: false, label: Text('Black')),
                          ],
                          selected: {playerIsP1},
                          onSelectionChanged: (s) => setState(() => playerIsP1 = s.first),
                        ),
                      ),
                       const _Divider(),
                      SwitchListTile(
                        title: const Text('Play vs Computer', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Experience high-performance AI'),
                        value: vsAi,
                        onChanged: (v) => setState(() => vsAi = v),
                        activeColor: const Color(0xFF4DD0E1),
                      ),
                    ],
                  ),
                ),
                
                if (vsAi) ...[
                  _SectionHeader(title: 'AI Intelligence'),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Challenge Tier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tiers.map((tier) {
                            final unlocked = widget.profile.unlockedAiTiers.contains(tier.id);
                            final selected = aiTierId == tier.id;
                            return GestureDetector(
                              onTap: unlocked ? () => setState(() => aiTierId = tier.id) : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF4DD0E1) : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? Colors.white.withOpacity(0.3) : (unlocked ? Colors.white.withOpacity(0.1) : Colors.transparent),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!unlocked) ...[
                                      const Icon(Icons.lock_rounded, size: 14, color: Colors.white38),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      tier.label.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: selected ? Colors.black : (unlocked ? Colors.white : Colors.white38),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             const Text('Refinement Level', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white70)),
                             Text('$aiLevel', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4DD0E1))),
                          ],
                        ),
                        Slider(
                          value: aiLevel.toDouble(),
                          min: 1,
                          max: 300,
                          activeColor: const Color(0xFF4DD0E1),
                          inactiveColor: Colors.white10,
                          onChanged: (v) => setState(() => aiLevel = v.round()),
                        ),
                      ],
                    ),
                  ),
                ],

                _SectionHeader(title: 'Aesthetics'),
                _GlassCard(
                   child: Column(
                     children: [
                        _SettingRow(
                          title: 'Board Design',
                          subtitle: boardSkins.firstWhere((s) => s.id == boardSkinId).name,
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
                        ),
                        const _Divider(),
                        _SettingRow(
                          title: 'Seed Design',
                          subtitle: seedSkins.firstWhere((s) => s.id == seedSkinId).name,
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
                        ),
                     ],
                   ),
                ),

                _SectionHeader(title: 'Feedback & Audio'),
                _GlassCard(
                  child: Column(
                    children: [
                      _ToggleRow(title: 'Sound Effects', value: soundOn, onChanged: (v) => setState(() => soundOn = v)),
                      const _Divider(),
                      _ToggleRow(title: 'Ambience Music', value: musicOn, onChanged: (v) => setState(() => musicOn = v)),
                      const _Divider(),
                      _ToggleRow(title: 'Tactile Haptics', value: hapticsOn, onChanged: (v) => setState(() => hapticsOn = v)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 16),
      child: Text(title.toUpperCase(), 
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white38)),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.subtitle, required this.trailing});
  final String title;
  final String subtitle;
  final Widget trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF4DD0E1)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Colors.white.withOpacity(0.05), height: 1),
    );
  }
}
