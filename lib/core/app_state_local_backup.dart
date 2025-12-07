import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/job_post.dart';
import '../models/subscription.dart';
import 'file_store.dart';
import 'notification_service.dart';

class AppState {
  static final AppState I = AppState._();
  AppState._();

  final _uuid = const Uuid();

  final List<Expense> expenses = [];
  final List<JobPost> jobs = [];
  final List<Subscription> subscriptions = [];

  // Monthly budget in cents
  int? monthlyBudgetCents;

  // Sent budget alert markers (to avoid duplicate alerts)
  final Set<String> _sentBudgetAlerts = {};

  // Sent subscription alert markers (to avoid duplicate alerts)
  final Set<String> _sentSubscriptionAlerts = {};

  Future<void> load() async {
    final e = await FileStore.read('expenses');
    final j = await FileStore.read('jobs');
    final b = await FileStore.read('budget');
    final s = await FileStore.read('subscriptions');

    expenses
      ..clear()
      ..addAll(((e['items'] ?? []) as List)
          .map((x) => Expense.fromJson(Map<String, dynamic>.from(x))));
    jobs
      ..clear()
      ..addAll(((j['items'] ?? []) as List)
          .map((x) => JobPost.fromJson(Map<String, dynamic>.from(x))));
    subscriptions
      ..clear()
      ..addAll(((s['items'] ?? []) as List)
          .map((x) => Subscription.fromJson(Map<String, dynamic>.from(x))));

    // Load budget settings
    monthlyBudgetCents = b['monthly_budget_cents'] as int?;

    // Load sent alert markers
    _sentBudgetAlerts.clear();
    if (b['sent_alerts'] != null) {
      _sentBudgetAlerts.addAll((b['sent_alerts'] as List).cast<String>());
    }

    _sentSubscriptionAlerts.clear();
    if (s['sent_alerts'] != null) {
      _sentSubscriptionAlerts.addAll((s['sent_alerts'] as List).cast<String>());
    }
  }

  Future<void> save() async {
    await FileStore.write('expenses', {'items': expenses.map((x)=>x.toJson()).toList()});
    await FileStore.write('jobs', {'items': jobs.map((x)=>x.toJson()).toList()});
  }

  Future<void> saveBudget() async {
    await FileStore.write('budget', {
      'monthly_budget_cents': monthlyBudgetCents,
      'sent_alerts': _sentBudgetAlerts.toList(),
    });
  }

  Future<void> saveSubscriptions() async {
    await FileStore.write('subscriptions', {
      'items': subscriptions.map((x) => x.toJson()).toList(),
      'sent_alerts': _sentSubscriptionAlerts.toList(),
    });
  }

  Future<void> addExpense({
    required double amountYuan,
    required String category,
    String? note,
    DateTime? date,
  }) async {
    final now = DateTime.now();
    expenses.add(
      Expense(
        id: _uuid.v4(),
        amountCents: (amountYuan * 100).round(),
        category: category,
        note: note,
        spendDate: DateTime((date ?? now).year, (date ?? now).month, (date ?? now).day),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await save();

    // Check budget and send alerts
    await _checkAndNotifyBudget();
  }

  // Check budget and send notifications
  Future<void> _checkAndNotifyBudget() async {
    final alertType = checkBudgetAlert();
    if (alertType != null) {
      final spent = getMonthlySpending();
      final budget = monthlyBudgetCents! / 100;

      await NotificationService.I.sendBudgetAlert(
        percentage: alertType,
        spent: spent,
        budget: budget,
      );
    }
  }

  Future<void> addJob({
    required String title,
    required String pay,
    required String contact,
    required String location,
    required String desc,
  }) async {
    jobs.add(JobPost(
      id: _uuid.v4(),
      title: title,
      pay: pay,
      contact: contact,
      location: location,
      desc: desc,
      createdAt: DateTime.now(),
    ));
    await save();
  }

  // Set monthly budget
  Future<void> setMonthlyBudget(double budgetYuan) async {
    monthlyBudgetCents = (budgetYuan * 100).round();
    await saveBudget();
  }

  // Get monthly spending
  double getMonthlySpending() {
    final now = DateTime.now();
    return expenses
        .where((e) => e.spendDate.year == now.year && e.spendDate.month == now.month)
        .fold<double>(0, (sum, e) => sum + e.amountCents / 100);
  }

  // Get budget usage percentage
  double getBudgetUsagePercentage() {
    if (monthlyBudgetCents == null || monthlyBudgetCents == 0) {
      return 0;
    }
    final spending = getMonthlySpending();
    final budget = monthlyBudgetCents! / 100;
    return (spending / budget * 100).clamp(0, 100);
  }

  // Get remaining budget
  double getRemainingBudget() {
    if (monthlyBudgetCents == null) {
      return 0;
    }
    final spending = getMonthlySpending();
    final budget = monthlyBudgetCents! / 100;
    return (budget - spending).clamp(0, budget);
  }

  // Check if budget alert should be sent
  String? checkBudgetAlert() {
    if (monthlyBudgetCents == null || monthlyBudgetCents == 0) {
      return null;
    }

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';
    final percentage = getBudgetUsagePercentage();

    // Check if 100% reached
    if (percentage >= 100) {
      final alertKey = '$monthKey-100';
      if (!_sentBudgetAlerts.contains(alertKey)) {
        _sentBudgetAlerts.add(alertKey);
        saveBudget();
        return '100';
      }
    }
    // Check if 80% reached
    else if (percentage >= 80) {
      final alertKey = '$monthKey-80';
      if (!_sentBudgetAlerts.contains(alertKey)) {
        _sentBudgetAlerts.add(alertKey);
        saveBudget();
        return '80';
      }
    }

    return null;
  }

  // Reset monthly alert markers (for new month)
  void resetMonthlyAlerts() {
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month}';
    _sentBudgetAlerts.removeWhere((key) => !key.startsWith(currentMonthKey));
    saveBudget();
  }

  // ==================== Subscription Management ====================

  /// Add subscription
  Future<void> addSubscription({
    required String name,
    required double amountYuan,
    required SubscriptionCycle cycle,
    required int billingDay,
    required String category,
    String? note,
  }) async {
    final now = DateTime.now();
    subscriptions.add(
      Subscription(
        id: _uuid.v4(),
        name: name,
        amountCents: (amountYuan * 100).round(),
        cycle: cycle,
        billingDay: billingDay,
        category: category,
        note: note,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await saveSubscriptions();
  }

  /// Update subscription
  Future<void> updateSubscription(Subscription subscription) async {
    final index = subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      subscriptions[index] = subscription;
      await saveSubscriptions();
    }
  }

  /// Delete subscription
  Future<void> deleteSubscription(String id) async {
    subscriptions.removeWhere((s) => s.id == id);
    await saveSubscriptions();
  }

  /// Toggle subscription active status
  Future<void> toggleSubscription(String id) async {
    final index = subscriptions.indexWhere((s) => s.id == id);
    if (index != -1) {
      subscriptions[index] = subscriptions[index].copyWith(
        isActive: !subscriptions[index].isActive,
      );
      await saveSubscriptions();
    }
  }

  /// Get active subscriptions
  List<Subscription> getActiveSubscriptions() {
    return subscriptions.where((s) => s.isActive).toList();
  }

  /// Get upcoming subscriptions (within 3 days)
  List<Subscription> getUpcomingSubscriptions() {
    return getActiveSubscriptions()
        .where((s) => s.shouldNotify())
        .toList()
      ..sort((a, b) => a.getDaysUntilNextBilling().compareTo(b.getDaysUntilNextBilling()));
  }

  /// Get subscriptions due today
  List<Subscription> getTodayBillingSubscriptions() {
    return getActiveSubscriptions().where((s) => s.shouldBillToday()).toList();
  }

  /// Check and send subscription alerts
  Future<void> checkSubscriptionAlerts() async {
    final upcoming = getUpcomingSubscriptions();

    for (final sub in upcoming) {
      final daysUntil = sub.getDaysUntilNextBilling();
      final alertKey = '${sub.id}-${sub.getNextBillingDate().toIso8601String().split('T')[0]}';

      if (!_sentSubscriptionAlerts.contains(alertKey)) {
        _sentSubscriptionAlerts.add(alertKey);
        await saveSubscriptions();

        await NotificationService.I.sendSubscriptionAlert(
          name: sub.name,
          amount: sub.amountYuan,
          daysUntil: daysUntil,
        );
      }
    }
  }

  /// Process today's subscription billings
  Future<void> processTodayBillings() async {
    final todayBillings = getTodayBillingSubscriptions();

    for (final sub in todayBillings) {
      // Create expense record
      await addExpense(
        amountYuan: sub.amountYuan,
        category: sub.category,
        note: '${sub.name} (Auto-billed)',
        date: DateTime.now(),
      );

      // Update last billed date
      final updated = sub.copyWith(
        lastBilledDate: DateTime.now(),
      );
      await updateSubscription(updated);
    }
  }

  /// Get monthly subscription total
  double getMonthlySubscriptionTotal() {
    return getActiveSubscriptions()
        .where((s) => s.cycle == SubscriptionCycle.monthly)
        .fold<double>(0, (sum, s) => sum + s.amountYuan);
  }
}