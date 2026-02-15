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
      backgroundColor: const Color(0xFF2D1F17),
      appBar: AppBar(
        title: const Text('Merchant\'s Stall'),
        backgroundColor: const Color(0xFF3E2723),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A3428), Color(0xFF3E2723)],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54F), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.profile.coins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFFB300),
          labelColor: const Color(0xFFFFD54F),
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Boards'),
            Tab(text: 'Seeds'),
            Tab(text: 'Boosts'),
            Tab(text: 'AI Tiers'),
          ],
        ),
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
        SnackBar(
          content: const Text('Not enough coins'),
          backgroundColor: const Color(0xFF8D6E63),
        ),
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
      SnackBar(
        content: Text('${item.name} unlocked!'),
        backgroundColor: const Color(0xFF4A3428),
      ),
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
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        final owned = isOwned(item);
        
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: owned
                  ? [
                      const Color(0xFF4A3428).withOpacity(0.5),
                      const Color(0xFF3E2723).withOpacity(0.5),
                    ]
                  : [
                      const Color(0xFF4A3428),
                      const Color(0xFF3E2723),
                    ],
            ),
            border: Border.all(
              color: owned
                  ? const Color(0xFF8D6E63).withOpacity(0.3)
                  : const Color(0xFFFFB300).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: owned
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Item icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: owned
                        ? [const Color(0xFF8D6E63), const Color(0xFF6D4C41)]
                        : [const Color(0xFFFFD54F), const Color(0xFFFFB300)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (owned ? const Color(0xFF8D6E63) : const Color(0xFFFFB300))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _getIconForType(item.type),
                  color: owned ? Colors.white.withOpacity(0.5) : const Color(0xFF3E2723),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: owned ? Colors.white.withOpacity(0.5) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: owned
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Price and buy button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!owned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF2D1F17),
                        border: Border.all(
                          color: const Color(0xFFFFB300).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFFFD54F),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.cost}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFD54F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: owned ? null : () => onBuy(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: owned
                          ? const Color(0xFF8D6E63).withOpacity(0.3)
                          : const Color(0xFFFFB300),
                      foregroundColor: owned ? Colors.white.withOpacity(0.5) : const Color(0xFF3E2723),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: owned ? 0 : 4,
                    ),
                    child: Text(
                      owned ? 'Owned' : 'Buy',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForType(StoreItemType type) {
    switch (type) {
      case StoreItemType.board:
        return Icons.grid_on_rounded;
      case StoreItemType.seed:
        return Icons.circle;
      case StoreItemType.boost:
        return Icons.flash_on_rounded;
      case StoreItemType.aiTier:
        return Icons.psychology_rounded;
    }
  }
}

