import 'dart:math';
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

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canClaim = widget.profile.canClaimDaily();
    return Scaffold(
      body: Stack(
        children: [
          // Warm gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.3, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFF2D1F17), // Warm dark brown
                  Color(0xFF1A1410), // Deep charcoal
                  Color(0xFF0F0A08), // Almost black
                ],
              ),
            ),
          ),
          // Floating particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(_particleController.value),
                size: Size.infinite,
              );
            },
          ),
          // Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Hero title
                      _HeroTitle(),
                      const SizedBox(height: 8),
                      // Subtitle
                      Center(
                        child: Text(
                          'Nigerian Strategy • Premium Board Game',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFFFFB300).withOpacity(0.7),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Coin balance
                      _CoinBalance(coins: widget.profile.coins),
                      const SizedBox(height: 16),
                      // Daily reward
                      if (canClaim)
                        _DailyRewardBanner(
                          onClaim: () async {
                            final reward = widget.profile.claimDaily();
                            await widget.profile.save();
                            if (mounted) setState(() {});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Daily reward claimed: +$reward coins'),
                                  backgroundColor: const Color(0xFF3E2723),
                                ),
                              );
                            }
                          },
                        ),
                      if (canClaim) const SizedBox(height: 16),
                      // Menu cards
                      Expanded(
                        child: ListView(
                          children: [
                            _WoodCard(
                              icon: Icons.play_circle_rounded,
                              label: 'Play Solo',
                              subtitle: 'Challenge the AI',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GameScreen(settings: widget.settings, profile: widget.profile),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _WoodCard(
                              icon: Icons.map_rounded,
                              label: 'Campaign',
                              subtitle: '300 levels of mastery',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LevelMapScreen(settings: widget.settings, profile: widget.profile),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _WoodCard(
                              icon: Icons.people_rounded,
                              label: 'Multiplayer',
                              subtitle: 'Local or nearby',
                              onTap: () => _openMultiplayer(context),
                            ),
                            const SizedBox(height: 12),
                            _WoodCard(
                              icon: Icons.storefront_rounded,
                              label: 'Store',
                              subtitle: 'Unlock boards & seeds',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StoreScreen(profile: widget.profile),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SmallWoodCard(
                                    icon: Icons.tune_rounded,
                                    label: 'Settings',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => SettingsScreen(settings: widget.settings, profile: widget.profile),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SmallWoodCard(
                                    icon: Icons.info_outline_rounded,
                                    label: 'About',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const AboutScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Footer
                      Center(
                        child: Text(
                          'Handcrafted with care',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.3),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
      backgroundColor: const Color(0xFF2D1F17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Multiplayer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFFB300),
                ),
              ),
              const SizedBox(height: 20),
              _MultiplayerOption(
                icon: Icons.phone_iphone_rounded,
                title: 'Local Pass-and-Play',
                subtitle: 'Two players, one device',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(settings: widget.settings, profile: widget.profile, forceVsAi: false),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MultiplayerOption(
                icon: Icons.wifi_tethering_rounded,
                title: 'Nearby Connections',
                subtitle: 'Bluetooth or WiFi Direct',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiplayerScreen(settings: widget.settings, profile: widget.profile),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _HeroTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // Shadow layer
          Text(
            'DARAH',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..color = Colors.black.withOpacity(0.5)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
            ),
          ),
          // Main text with gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFD54F), // Gold
                Color(0xFFFFB300), // Amber
                Color(0xFFFFA000), // Deep amber
              ],
            ).createShader(bounds),
            child: const Text(
              'DARAH',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinBalance extends StatelessWidget {
  const _CoinBalance({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2723), Color(0xFF2D1F17)],
        ),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 24),
          const SizedBox(width: 10),
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD54F),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'COINS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRewardBanner extends StatelessWidget {
  const _DailyRewardBanner({required this.onClaim});
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClaim,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF4A3428), Color(0xFF3E2723)],
          ),
          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD54F), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Reward Ready!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFD54F)),
                  ),
                  Text(
                    'Tap to claim your coins',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFB300), size: 18),
          ],
        ),
      ),
    );
  }
}

class _WoodCard extends StatelessWidget {
  const _WoodCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A3428), Color(0xFF3E2723)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFFFD54F), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallWoodCard extends StatelessWidget {
  const _SmallWoodCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A3428), Color(0xFF3E2723)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFFFD54F), size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiplayerOption extends StatelessWidget {
  const _MultiplayerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFB300), size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB300).withOpacity(0.1);
    final random = Random(42);
    
    for (var i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + progress * size.height * 0.3) % size.height;
      final radius = 1.5 + random.nextDouble() * 2;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
