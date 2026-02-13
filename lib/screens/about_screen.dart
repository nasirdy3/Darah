import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Darah (Dara)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'A Nigerian/African strategy board game.\n\n'
              'This app is offline-first and designed for smooth mobile play.\n\n'
              'Rules:\n'
              '- Placement: cannot form 3-in-a-row.\n'
              '- Movement: orthogonal step only.\n'
              '- Dara: exact 3-in-row -> capture one opponent seed.\n'
              '- 4+ in a row is illegal.\n'
              '- Multiple Daras in one move are NOT allowed.\n'
              '- Win when opponent has fewer than 3 seeds or no legal moves.',
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: 0.7,
              child: Text(
                'Offline premium build. Flutter. Android.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
