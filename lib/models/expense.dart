class Expense {
  final String id;
  final int amountCents;
  final String category;
  final String? note;
  final DateTime spendDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.amountCents,
    required this.category,
    this.note,
    required this.spendDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount_cents': amountCents,
    'category': category,
    'note': note,
    'spend_date': spendDate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  static Expense fromJson(Map<String, dynamic> m) => Expense(
    id: m['id'],
    amountCents: m['amount_cents'],
    category: m['category'],
    note: m['note'],
    spendDate: DateTime.parse(m['spend_date']),
    createdAt: DateTime.parse(m['created_at']),
    updatedAt: DateTime.parse(m['updated_at']),
  );
}