/// Subscription expense model
class Subscription {
  final String id;
  final String name;           // Subscription name (e.g., "Rent", "Netflix")
  final int amountCents;       // Amount in cents
  final SubscriptionCycle cycle; // Billing cycle
  final int billingDay;        // Billing day (1-31)
  final String category;       // Category
  final String? note;          // Note
  final bool isActive;         // Is active
  final DateTime? lastBilledDate; // Last billed date
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.name,
    required this.amountCents,
    required this.cycle,
    required this.billingDay,
    required this.category,
    this.note,
    this.isActive = true,
    this.lastBilledDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get amount in yuan
  double get amountYuan => amountCents / 100;

  /// Get next billing date
  DateTime getNextBillingDate() {
    final now = DateTime.now();
    DateTime nextDate;

    switch (cycle) {
      case SubscriptionCycle.monthly:
        // Monthly subscription
        nextDate = DateTime(now.year, now.month, billingDay);
        if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
          // If this month's billing day has passed, calculate next month
          nextDate = DateTime(now.year, now.month + 1, billingDay);
        }
        break;

      case SubscriptionCycle.yearly:
        // Yearly subscription
        if (lastBilledDate != null) {
          nextDate = DateTime(
            lastBilledDate!.year + 1,
            lastBilledDate!.month,
            lastBilledDate!.day,
          );
        } else {
          nextDate = DateTime(now.year, now.month, billingDay);
          if (nextDate.isBefore(now)) {
            nextDate = DateTime(now.year + 1, now.month, billingDay);
          }
        }
        break;

      case SubscriptionCycle.weekly:
        // Weekly subscription
        if (lastBilledDate != null) {
          nextDate = lastBilledDate!.add(const Duration(days: 7));
        } else {
          // Find next specified weekday
          final targetWeekday = billingDay; // 1=Monday, 7=Sunday
          int daysUntilTarget = (targetWeekday - now.weekday) % 7;
          if (daysUntilTarget == 0) daysUntilTarget = 7;
          nextDate = now.add(Duration(days: daysUntilTarget));
        }
        break;

      case SubscriptionCycle.quarterly:
        // Quarterly subscription
        if (lastBilledDate != null) {
          nextDate = DateTime(
            lastBilledDate!.year,
            lastBilledDate!.month + 3,
            lastBilledDate!.day,
          );
        } else {
          nextDate = DateTime(now.year, now.month, billingDay);
          if (nextDate.isBefore(now)) {
            nextDate = DateTime(now.year, now.month + 3, billingDay);
          }
        }
        break;
    }

    return nextDate;
  }

  /// Get days until next billing
  int getDaysUntilNextBilling() {
    final nextDate = getNextBillingDate();
    final now = DateTime.now();
    return nextDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Check if notification is needed (3 days in advance)
  bool shouldNotify() {
    final daysUntil = getDaysUntilNextBilling();
    return daysUntil >= 0 && daysUntil <= 3;
  }

  /// Check if billing is due today
  bool shouldBillToday() {
    final nextDate = getNextBillingDate();
    final now = DateTime.now();
    return nextDate.year == now.year &&
        nextDate.month == now.month &&
        nextDate.day == now.day;
  }

  /// Copy with updates
  Subscription copyWith({
    String? name,
    int? amountCents,
    SubscriptionCycle? cycle,
    int? billingDay,
    String? category,
    String? note,
    bool? isActive,
    DateTime? lastBilledDate,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      cycle: cycle ?? this.cycle,
      billingDay: billingDay ?? this.billingDay,
      category: category ?? this.category,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      lastBilledDate: lastBilledDate ?? this.lastBilledDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amountCents': amountCents,
      'cycle': cycle.name,
      'billingDay': billingDay,
      'category': category,
      'note': note,
      'isActive': isActive,
      'lastBilledDate': lastBilledDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      amountCents: json['amountCents'] as int,
      cycle: SubscriptionCycle.values.firstWhere(
        (e) => e.name == json['cycle'],
        orElse: () => SubscriptionCycle.monthly,
      ),
      billingDay: json['billingDay'] as int,
      category: json['category'] as String,
      note: json['note'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastBilledDate: json['lastBilledDate'] != null
          ? DateTime.parse(json['lastBilledDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Subscription cycle
enum SubscriptionCycle {
  weekly,    // Weekly
  monthly,   // Monthly
  quarterly, // Quarterly
  yearly,    // Yearly
}

extension SubscriptionCycleExtension on SubscriptionCycle {
  String get displayName {
    switch (this) {
      case SubscriptionCycle.weekly:
        return 'Weekly';
      case SubscriptionCycle.monthly:
        return 'Monthly';
      case SubscriptionCycle.quarterly:
        return 'Quarterly';
      case SubscriptionCycle.yearly:
        return 'Yearly';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionCycle.weekly:
        return 'Billed once a week';
      case SubscriptionCycle.monthly:
        return 'Billed once a month';
      case SubscriptionCycle.quarterly:
        return 'Billed once every 3 months';
      case SubscriptionCycle.yearly:
        return 'Billed once a year';
    }
  }
}

