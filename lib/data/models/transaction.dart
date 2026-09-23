import 'category.dart';

/// A single recorded money movement.
class MoneyTransaction {
  const MoneyTransaction({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note = '',
    this.account = 'Cash',
  });

  final int? id;
  final double amount;
  final TxType type;
  final int categoryId;
  final DateTime date;
  final String note;
  final String account;

  bool get isIncome => type == TxType.income;

  /// Signed value used when computing balances.
  double get signedAmount => isIncome ? amount : -amount;

  MoneyTransaction copyWith({
    int? id,
    double? amount,
    TxType? type,
    int? categoryId,
    DateTime? date,
    String? note,
    String? account,
  }) =>
      MoneyTransaction(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        note: note ?? this.note,
        account: account ?? this.account,
      );

  factory MoneyTransaction.fromMap(Map<String, Object?> map) =>
      MoneyTransaction(
        id: map['id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        type: TxType.fromDb((map['type'] as String?) ?? 'expense'),
        categoryId: map['category_id'] as int,
        date: DateTime.parse(map['date'] as String),
        note: (map['note'] as String?) ?? '',
        account: (map['account'] as String?) ?? 'Cash',
      );

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'amount': amount,
        'type': type.db,
        'category_id': categoryId,
        'date': date.toIso8601String(),
        'note': note,
        'account': account,
      };
}
