import 'package:flutter/material.dart';

import '../state/profile_store.dart';
import '../state/settings_store.dart';
import 'about_screen.dart';
import 'game_screen.dart';
import 'level_map_screen.dart';
import 'multiplayer_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key, required this.settings, required this.profile});
  final SettingsStore settings;
  final ProfileStore profile;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    final canClaim = widget.profile.canClaimDaily();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF15100C), Color(0xFF0A0A0A)],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF7A5B3C).withOpacity(0.35), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF4B3A2B).withOpacity(0.35), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DARAH',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        letterSpacing: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Opacity(
                                  opacity: 0.8,
                                  child: Text(
                                    'Nigerian Strategy. Premium Board Game.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _CoinPill(coins: widget.profile.coins),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _DailyRewardCard(
                        canClaim: canClaim,
                        onClaim: () async {
                          final reward = widget.profile.claimDaily();
                          await widget.profile.save();
                          if (mounted) setState(() {});
                          if (context.mounted) {
                            final text = reward > 0 ? 'Daily reward +$reward coins' : 'Come back later';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      _MenuButton(
                        label: 'Start Game',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GameScreen(settings: widget.settings, profile: widget.profile),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        label: 'Level Map',
                        icon: Icons.map_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LevelMapScreen(settings: widget.settings, profile: widget.profile),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        label: 'Store',
                        icon: Icons.storefront_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StoreScreen(profile: widget.profile),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        label: 'Multiplayer',
                        icon: Icons.groups_rounded,
                        onPressed: () => _openMultiplayer(context),
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        label: 'Settings',
                        icon: Icons.tune_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(settings: widget.settings, profile: widget.profile),
                            ),
                          ).then((_) => setState(() {}));
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
                      const Spacer(),
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          'Offline premium build. AI tiers from Beginner to Impossible.',
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
        ],
      ),
    );
  }

  void _openMultiplayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF15110E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Multiplayer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.phone_iphone_rounded),
                title: const Text('Local Pass-and-Play'),
                subtitle: const Text('Two players, one device'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(settings: widget.settings, profile: widget.profile, forceVsAi: false),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.wifi_tethering_rounded),
                title: const Text('Bluetooth / WiFi'),
                subtitle: const Text('Nearby Connections'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiplayerScreen(settings: widget.settings, profile: widget.profile),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
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

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF2D2118).withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 18),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({required this.canClaim, required this.onClaim});
  final bool canClaim;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF21180F).withOpacity(0.85),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: Color(0xFFFFD54F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canClaim ? 'Daily reward ready' : 'Daily reward claimed',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            onPressed: canClaim ? onClaim : null,
            child: Text(canClaim ? 'Claim' : 'Come Back'),
          ),
        ],
      ),
    );
  }
}
