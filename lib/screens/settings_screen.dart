import 'package:flutter/material.dart';

import '../state/settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.settings});
  final SettingsStore settings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int boardSize;
  late bool vsAi;
  late int aiLevel;
  late bool playerIsP1;

  @override
  void initState() {
    super.initState();
    boardSize = widget.settings.boardSize;
    vsAi = widget.settings.vsAi;
    aiLevel = widget.settings.aiLevel;
    playerIsP1 = widget.settings.playerIsP1;
  }

  Future<void> _save() async {
    widget.settings.boardSize = boardSize;
    widget.settings.vsAi = vsAi;
    widget.settings.aiLevel = aiLevel;
    widget.settings.playerIsP1 = playerIsP1;
    await widget.settings.save();
  }

  @override
  Widget build(BuildContext context) {
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
                DropdownMenuItem(value: 5, child: Text('5×5 (6 seeds/player)')),
                DropdownMenuItem(value: 6, child: Text('6×6 (12 seeds/player)')),
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
                  subtitle: const Text('Turn off for pass-and-play (2 humans)'),
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
                Text('Level: $aiLevel', style: const TextStyle(fontWeight: FontWeight.w700)),
                Slider(
                  value: aiLevel.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '$aiLevel',
                  onChanged: vsAi ? (v) => setState(() => aiLevel = v.round()) : null,
                ),
                Opacity(
                  opacity: 0.7,
                  child: Text(_labelFor(aiLevel)),
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

  String _labelFor(int lvl) {
    if (lvl <= 10) return 'Beginner';
    if (lvl <= 20) return 'Amateur';
    if (lvl <= 30) return 'Professional';
    if (lvl <= 40) return 'Top';
    if (lvl <= 50) return 'Super';
    return 'Legend';
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
