enum ShopItemType { avatar, border, streakSaver }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    this.iconCodePoint,
    this.colorValue,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final ShopItemType type;
  final int? iconCodePoint;
  final int? colorValue;
}

const shopItems = [
  ShopItem(
    id: 'avatar_person',
    name: 'Classic',
    description: 'Your original adventurer avatar.',
    price: 0,
    type: ShopItemType.avatar,
    iconCodePoint: 0xe491,
  ),
  ShopItem(
    id: 'avatar_star',
    name: 'Star Scout',
    description: 'A bright new profile avatar.',
    price: 75,
    type: ShopItemType.avatar,
    iconCodePoint: 0xe838,
  ),
  ShopItem(
    id: 'avatar_rocket',
    name: 'Rocket',
    description: 'Ready to launch your next habit.',
    price: 75,
    type: ShopItemType.avatar,
    iconCodePoint: 0xe1a5,
  ),
  ShopItem(
    id: 'border_gold',
    name: 'Gold border',
    description: 'A reward-worthy profile border.',
    price: 100,
    type: ShopItemType.border,
    colorValue: 0xffffc107,
  ),
  ShopItem(
    id: 'border_blue',
    name: 'Sky border',
    description: 'A calm blue profile border.',
    price: 100,
    type: ShopItemType.border,
    colorValue: 0xff4f9cf9,
  ),
  ShopItem(
    id: 'border_emerald',
    name: 'Emerald border',
    description: 'A lively green profile border.',
    price: 100,
    type: ShopItemType.border,
    colorValue: 0xff62d6a7,
  ),
  ShopItem(
    id: 'border_violet',
    name: 'Violet border',
    description: 'A bold violet profile border.',
    price: 100,
    type: ShopItemType.border,
    colorValue: 0xffb388ff,
  ),
  ShopItem(
    id: 'border_rose',
    name: 'Rose border',
    description: 'A warm rose profile border.',
    price: 100,
    type: ShopItemType.border,
    colorValue: 0xffff8a9b,
  ),
  ShopItem(
    id: 'border_silver',
    name: 'Silver border',
    description: 'A polished silver profile border.',
    price: 100,
    type: ShopItemType.border,
    colorValue: 0xffc7d2e3,
  ),
  ShopItem(
    id: 'streak_saver',
    name: 'Streak saver',
    description: 'Automatically protects one missed day.',
    price: 150,
    type: ShopItemType.streakSaver,
  ),
];

ShopItem shopItemById(String id) => shopItems.firstWhere(
  (item) => item.id == id,
  orElse: () => shopItems.first,
);
