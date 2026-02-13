enum StoreItemType { board, seed, boost, aiTier }

class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.type,
    required this.cost,
    required this.description,
    this.payload,
  });

  final String id;
  final String name;
  final StoreItemType type;
  final int cost;
  final String description;
  final Map<String, dynamic>? payload;
}

final List<StoreItem> storeItems = [
  StoreItem(
    id: 'board_marble_elite',
    name: 'Marble Elite Board',
    type: StoreItemType.board,
    cost: 600,
    description: 'Elegant marble board with polished highlights.',
    payload: {'boardId': 'marble_elite'},
  ),
  StoreItem(
    id: 'board_ebony_luxury',
    name: 'Ebony Luxury Board',
    type: StoreItemType.board,
    cost: 750,
    description: 'Deep ebony board with gold accents.',
    payload: {'boardId': 'ebony_luxury'},
  ),
  StoreItem(
    id: 'board_tribal_earth',
    name: 'Tribal Earth Board',
    type: StoreItemType.board,
    cost: 520,
    description: 'Warm earth tones inspired by African art.',
    payload: {'boardId': 'tribal_earth'},
  ),
  StoreItem(
    id: 'board_neon_cyber',
    name: 'Neon Cyber Board',
    type: StoreItemType.board,
    cost: 900,
    description: 'Futuristic neon board with crisp glow.',
    payload: {'boardId': 'neon_cyber'},
  ),
  StoreItem(
    id: 'seed_gold_elite',
    name: 'Gold Elite Seeds',
    type: StoreItemType.seed,
    cost: 420,
    description: 'Gold and obsidian stones.',
    payload: {'seedId': 'gold_elite'},
  ),
  StoreItem(
    id: 'seed_crystal',
    name: 'Crystal Seeds',
    type: StoreItemType.seed,
    cost: 520,
    description: 'Glass-like crystal seeds.',
    payload: {'seedId': 'crystal'},
  ),
  StoreItem(
    id: 'seed_obsidian',
    name: 'Obsidian Seeds',
    type: StoreItemType.seed,
    cost: 580,
    description: 'Heavy obsidian stones with silver rims.',
    payload: {'seedId': 'obsidian'},
  ),
  StoreItem(
    id: 'seed_ember_fire',
    name: 'Ember Fire Seeds',
    type: StoreItemType.seed,
    cost: 680,
    description: 'Fiery glow with ember accents.',
    payload: {'seedId': 'ember_fire'},
  ),
  StoreItem(
    id: 'boost_hints',
    name: 'Hint Pack +3',
    type: StoreItemType.boost,
    cost: 140,
    description: 'Adds 3 extra hints to your inventory.',
    payload: {'hints': 3},
  ),
  StoreItem(
    id: 'boost_undos',
    name: 'Undo Pack +3',
    type: StoreItemType.boost,
    cost: 160,
    description: 'Adds 3 extra undos to your inventory.',
    payload: {'undos': 3},
  ),
  StoreItem(
    id: 'ai_grandmaster',
    name: 'AI Tier: Grandmaster',
    type: StoreItemType.aiTier,
    cost: 900,
    description: 'Unlock Grandmaster AI tier.',
    payload: {'tier': 'grandmaster'},
  ),
  StoreItem(
    id: 'ai_impossible',
    name: 'AI Tier: Impossible',
    type: StoreItemType.aiTier,
    cost: 1400,
    description: 'Unlock Impossible AI tier with adaptive play.',
    payload: {'tier': 'impossible'},
  ),
];
