import 'package:flutter/material.dart';

/// Whether a transaction adds to or subtracts from the balance.
enum TxType {
  income,
  expense;

  static TxType fromDb(String value) =>
      value == 'income' ? TxType.income : TxType.expense;

  String get db => name;
}

/// A spending or earning category. Names are stored in both languages so the
/// UI can switch locale without a round-trip to the database.
class Category {
  const Category({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.iconKey,
    required this.colorIndex,
    required this.kind,
  });

  final int id;
  final String nameEn;
  final String nameAr;
  final String iconKey;
  final int colorIndex;
  final TxType kind;

  String name(String languageCode) =>
      languageCode == 'ar' ? (nameAr.isEmpty ? nameEn : nameAr) : nameEn;

  IconData get icon => CategoryIcons.resolve(iconKey);

  Color get color => CategoryColors.resolve(colorIndex);

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int,
        nameEn: (map['name_en'] as String?) ?? '',
        nameAr: (map['name_ar'] as String?) ?? '',
        iconKey: (map['icon'] as String?) ?? 'category',
        colorIndex: (map['color'] as int?) ?? 0,
        kind: TxType.fromDb((map['kind'] as String?) ?? 'expense'),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        if (id > 0) 'id': id,
        'name_en': nameEn,
        'name_ar': nameAr,
        'icon': iconKey,
        'color': colorIndex,
        'kind': kind.db,
      };
}

/// Resolves stored icon keys to tree-shakeable [IconData] constants.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _map = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'groceries': Icons.local_grocery_store_rounded,
    'transport': Icons.directions_car_filled_rounded,
    'home': Icons.home_rounded,
    'bills': Icons.receipt_long_rounded,
    'health': Icons.favorite_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'entertainment': Icons.movie_rounded,
    'education': Icons.school_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'salary': Icons.account_balance_wallet_rounded,
    'freelance': Icons.work_rounded,
    'gift': Icons.card_giftcard_rounded,
    'savings': Icons.savings_rounded,
    'coffee': Icons.local_cafe_rounded,
    'fitness': Icons.fitness_center_rounded,
    'pets': Icons.pets_rounded,
    'category': Icons.category_rounded,
  };

  static IconData resolve(String key) => _map[key] ?? Icons.category_rounded;

  static List<String> get keys => _map.keys.toList(growable: false);
}

/// Maps a palette index to a concrete colour.
class CategoryColors {
  CategoryColors._();

  static const List<Color> _palette = <Color>[
    Color(0xFF0E7C66),
    Color(0xFFE8A33D),
    Color(0xFF4C6FFF),
    Color(0xFFE4572E),
    Color(0xFF8E5BD9),
    Color(0xFF1E9E6A),
    Color(0xFFD64550),
    Color(0xFF2AA7C4),
    Color(0xFFB4872E),
    Color(0xFF6B7A8F),
  ];

  static Color resolve(int index) => _palette[index % _palette.length];

  static int get length => _palette.length;
}
