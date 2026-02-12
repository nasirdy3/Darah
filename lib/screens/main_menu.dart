import 'package:flutter/material.dart';

import '../state/settings_store.dart';
import 'settings_screen.dart';
import 'game_screen.dart';
import 'about_screen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key, required this.settings});
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1512), Color(0xFF0F0D0B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'DARAH',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            letterSpacing: 6,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        'Dara • Nigerian / African Strategy',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _MenuButton(
                      label: 'Start Game',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(settings: settings),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      label: 'Settings',
                      icon: Icons.tune_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(settings: settings),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      label: 'About',
                      icon: Icons.info_outline_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      label: 'Multiplayer (Coming Soon)',
                      icon: Icons.wifi_tethering,
                      enabled: false,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: 0.55,
                      child: Text(
                        'Offline v1 • Premium UI • AI 1–100',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
