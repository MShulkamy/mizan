/// A monthly spending limit attached to a category.
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
  });

  final int id;
  final int categoryId;
  final double limit;

  factory Budget.fromMap(Map<String, Object?> map) => Budget(
        id: map['id'] as int,
        categoryId: map['category_id'] as int,
        limit: (map['amount'] as num).toDouble(),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        if (id > 0) 'id': id,
        'category_id': categoryId,
        'amount': limit,
      };
}
