import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1F17),
      appBar: AppBar(
        title: const Text('About Darah'),
        backgroundColor: const Color(0xFF3E2723),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF3E2723),
              const Color(0xFF2D1F17),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leather-bound book page
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF8E1),
                      Color(0xFFFFF3E0),
                      Color(0xFFFFECB3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF8D6E63),
                    width: 3,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ornate title
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'DARAH',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3E2723),
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFD7C0AE).withOpacity(0.5),
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 120,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF8D6E63),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nigerian Strategy Game',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF8D6E63),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Game description
                    _buildSection(
                      'About the Game',
                      'Darah (also known as Dara) is a traditional Nigerian strategy board game '
                      'that has been played for generations across West Africa. This premium digital '
                      'adaptation brings the ancient game to modern devices while preserving its '
                      'strategic depth and cultural heritage.',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Rules section
                    _buildSection(
                      'How to Play',
                      '',
                    ),
                    _buildRule('Placement Phase', 'Players take turns placing seeds on the board. You cannot form 3-in-a-row during placement.'),
                    _buildRule('Movement Phase', 'Move seeds orthogonally (one step only). No diagonal moves or jumping.'),
                    _buildRule('Forming Dara', 'Create exactly 3-in-a-row to capture one opponent seed. Four or more in a row is illegal.'),
                    _buildRule('Victory', 'Win when your opponent has fewer than 3 seeds or no legal moves.'),
                    
                    const SizedBox(height: 20),
                    
                    // Features
                    _buildSection(
                      'Features',
                      '• 300 handcrafted levels with progressive difficulty\n'
                      '• Advanced AI from Beginner to Impossible\n'
                      '• Local multiplayer (pass-and-play)\n'
                      '• Nearby Connections (Bluetooth/WiFi)\n'
                      '• Unlockable boards and seed skins\n'
                      '• Offline-first design',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 1,
                            color: const Color(0xFFD7C0AE),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Handcrafted with care',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF8D6E63).withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Premium Offline Build',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF8D6E63).withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3E2723),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (content.isNotEmpty)
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF3E2723).withOpacity(0.8),
            ),
          ),
      ],
    );
  }

  Widget _buildRule(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF3E2723).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

