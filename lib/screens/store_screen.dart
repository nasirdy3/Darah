import 'package:flutter/material.dart';

import '../progression/store_catalog.dart';
import '../state/profile_store.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.profile});
  final ProfileStore profile;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 18),
                  const SizedBox(width: 6),
                  Text('${widget.profile.coins}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Boards'),
            Tab(text: 'Seeds'),
            Tab(text: 'Boosts'),
            Tab(text: 'AI Tiers'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF120E0B), Color(0xFF080705)],
          ),
        ),
        child: TabBarView(
          controller: _tabs,
          children: [
            _StoreList(
              items: storeItems.where((i) => i.type == StoreItemType.board).toList(),
              onBuy: _handleBuy,
              isOwned: _isOwned,
            ),
            _StoreList(
              items: storeItems.where((i) => i.type == StoreItemType.seed).toList(),
              onBuy: _handleBuy,
              isOwned: _isOwned,
            ),
            _StoreList(
              items: storeItems.where((i) => i.type == StoreItemType.boost).toList(),
              onBuy: _handleBuy,
              isOwned: _isOwned,
            ),
            _StoreList(
              items: storeItems.where((i) => i.type == StoreItemType.aiTier).toList(),
              onBuy: _handleBuy,
              isOwned: _isOwned,
            ),
          ],
        ),
      ),
    );
  }

  bool _isOwned(StoreItem item) {
    final payload = item.payload ?? {};
    switch (item.type) {
      case StoreItemType.board:
        return widget.profile.unlockedBoards.contains(payload['boardId']);
      case StoreItemType.seed:
        return widget.profile.unlockedSeeds.contains(payload['seedId']);
      case StoreItemType.aiTier:
        return widget.profile.unlockedAiTiers.contains(payload['tier']);
      case StoreItemType.boost:
        return false;
    }
  }

  Future<void> _handleBuy(StoreItem item) async {
    if (!widget.profile.spendCoins(item.cost)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
      return;
    }

    final payload = item.payload ?? {};
    switch (item.type) {
      case StoreItemType.board:
        widget.profile.unlockedBoards.add(payload['boardId'] as String);
        widget.profile.equippedBoard = payload['boardId'] as String;
        break;
      case StoreItemType.seed:
        widget.profile.unlockedSeeds.add(payload['seedId'] as String);
        widget.profile.equippedSeed = payload['seedId'] as String;
        break;
      case StoreItemType.boost:
        widget.profile.extraHints += (payload['hints'] ?? 0) as int;
        widget.profile.extraUndos += (payload['undos'] ?? 0) as int;
        break;
      case StoreItemType.aiTier:
        widget.profile.unlockedAiTiers.add(payload['tier'] as String);
        break;
    }

    await widget.profile.save();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} unlocked')),
    );
  }
}

class _StoreList extends StatelessWidget {
  const _StoreList({required this.items, required this.onBuy, required this.isOwned});
  final List<StoreItem> items;
  final Future<void> Function(StoreItem item) onBuy;
  final bool Function(StoreItem item) isOwned;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final owned = isOwned(item);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF1B1510),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(item.description, style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 16),
                      const SizedBox(width: 4),
                      Text('${item.cost}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: owned ? null : () => onBuy(item),
                    child: Text(owned ? 'Owned' : 'Buy'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
