import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/job_post.dart';
import '../models/subscription.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

/// AppState with Firestore integration
/// This version uses cloud storage instead of local files
class AppState {
  static final AppState I = AppState._();
  AppState._();

  final _uuid = const Uuid();
  final _firestore = FirestoreService.I;

  final List<Expense> expenses = [];
  final List<JobPost> jobs = [];
  final List<Subscription> subscriptions = [];

  // User role
  bool isAdmin = false;

  // Monthly budget in cents
  int? monthlyBudgetCents;

  // Sent budget alert markers (to avoid duplicate alerts)
  final Set<String> _sentBudgetAlerts = {};

  // Sent subscription alert markers (to avoid duplicate alerts)
  final Set<String> _sentSubscriptionAlerts = {};

  /// Load all data from Firestore
  Future<void> load() async {
    try {
      // Load user role
      isAdmin = await _firestore.isUserAdmin();

      // Load expenses
      final loadedExpenses = await _firestore.getExpenses();
      expenses
        ..clear()
        ..addAll(loadedExpenses);

      // Load subscriptions
      final loadedSubscriptions = await _firestore.getSubscriptions();
      subscriptions
        ..clear()
        ..addAll(loadedSubscriptions);

      // Load jobs
      final loadedJobs = await _firestore.getJobs();
      jobs
        ..clear()
        ..addAll(loadedJobs);

      // Load budget settings
      final budgetData = await _firestore.getBudget();
      monthlyBudgetCents = budgetData['monthly_budget_cents'] as int?;

      // Load sent alert markers
      _sentBudgetAlerts.clear();
      if (budgetData['sent_alerts'] != null) {
        final alerts = budgetData['sent_alerts'];
        if (alerts is List) {
          _sentBudgetAlerts.addAll(alerts.map((e) => e.toString()));
        }
      }

      // Load subscription alerts
      final subscriptionAlerts = await _firestore.getSentSubscriptionAlerts();
      _sentSubscriptionAlerts.clear();
      _sentSubscriptionAlerts.addAll(subscriptionAlerts);

      print('✅ Data loaded from Firestore successfully');
    } catch (e) {
      print('❌ Error loading data from Firestore: $e');
    }
  }

  /// Save expenses and jobs to Firestore
  Future<void> save() async {
    // Note: Individual items are saved when added/updated
    // This method is kept for compatibility but doesn't need to do anything
    // since Firestore saves immediately
  }

  /// Save budget settings to Firestore
  Future<void> saveBudget() async {
    try {
      await _firestore.saveBudget({
        'monthly_budget_cents': monthlyBudgetCents,
        'sent_alerts': _sentBudgetAlerts.toList(),
      });
    } catch (e) {
      print('Error saving budget: $e');
    }
  }

  /// Save subscriptions to Firestore
  Future<void> saveSubscriptions() async {
    try {
      await _firestore.saveSentSubscriptionAlerts(_sentSubscriptionAlerts);
    } catch (e) {
      print('Error saving subscription alerts: $e');
    }
  }

  // ==================== Expense Management ====================

  Future<void> addExpense({
    required double amountYuan,
    required String category,
    String? note,
    DateTime? date,
  }) async {
    final now = DateTime.now();
    final expense = Expense(
      id: _uuid.v4(),
      amountCents: (amountYuan * 100).round(),
      category: category,
      note: note,
      spendDate: DateTime((date ?? now).year, (date ?? now).month, (date ?? now).day),
      createdAt: now,
      updatedAt: now,
    );

    // Add to local list
    expenses.add(expense);

    // Save to Firestore
    await _firestore.addExpense(expense);

    // Check budget and send alerts
    await _checkAndNotifyBudget();
  }

  Future<void> deleteExpense(String expenseId) async {
    // Remove from local list
    expenses.removeWhere((e) => e.id == expenseId);

    // Delete from Firestore
    await _firestore.deleteExpense(expenseId);
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

  // ==================== Job Management ====================

  Future<void> addJob({
    required String title,
    required String pay,
    required String contact,
    required String location,
    required String desc,
  }) async {
    final job = JobPost(
      id: _uuid.v4(),
      title: title,
      pay: pay,
      contact: contact,
      location: location,
      desc: desc,
      createdAt: DateTime.now(),
    );

    // Add to local list
    jobs.add(job);

    // Save to Firestore
    await _firestore.addJob(job);
  }

  Future<void> deleteJob(String jobId) async {
    // Remove from local list
    jobs.removeWhere((j) => j.id == jobId);

    // Delete from Firestore
    await _firestore.deleteJob(jobId);
  }

  // ==================== Budget Management ====================

  /// Set monthly budget
  Future<void> setMonthlyBudget(double budgetYuan) async {
    monthlyBudgetCents = (budgetYuan * 100).round();
    await saveBudget();
  }

  double getMonthlySpending() {
    final now = DateTime.now();
    final monthExpenses = expenses.where((e) =>
        e.spendDate.year == now.year && e.spendDate.month == now.month);
    return monthExpenses.fold(0.0, (sum, e) => sum + e.amountCents / 100);
  }

  /// Get budget usage percentage
  double getBudgetUsagePercentage() {
    if (monthlyBudgetCents == null || monthlyBudgetCents == 0) {
      return 0;
    }
    final spending = getMonthlySpending();
    final budget = monthlyBudgetCents! / 100;
    return (spending / budget * 100).clamp(0, 100);
  }

  /// Get remaining budget
  double getRemainingBudget() {
    if (monthlyBudgetCents == null) {
      return 0;
    }
    final spending = getMonthlySpending();
    final budget = monthlyBudgetCents! / 100;
    return budget - spending;
  }

  String? checkBudgetAlert() {
    if (monthlyBudgetCents == null) return null;
    final spent = getMonthlySpending();
    final budget = monthlyBudgetCents! / 100;
    final percentage = (spent / budget * 100).round();

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month}';

    if (percentage >= 100 && !_sentBudgetAlerts.contains('$monthKey-100')) {
      _sentBudgetAlerts.add('$monthKey-100');
      saveBudget();
      return '100';
    } else if (percentage >= 80 && !_sentBudgetAlerts.contains('$monthKey-80')) {
      _sentBudgetAlerts.add('$monthKey-80');
      saveBudget();
      return '80';
    }
    return null;
  }

  // ==================== Subscription Management ====================

  Future<void> addSubscription({
    required String name,
    required double amountYuan,
    required SubscriptionCycle cycle,
    required int billingDay,
    required String category,
    String? note,
  }) async {
    final now = DateTime.now();
    final subscription = Subscription(
      id: _uuid.v4(),
      name: name,
      amountCents: (amountYuan * 100).round(),
      cycle: cycle,
      billingDay: billingDay,
      category: category,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    // Add to local list
    subscriptions.add(subscription);

    // Save to Firestore
    await _firestore.addSubscription(subscription);
  }

  Future<void> updateSubscription(Subscription subscription) async {
    // Update in local list
    final index = subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      subscriptions[index] = subscription;
    }

    // Update in Firestore
    await _firestore.updateSubscription(subscription);
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    // Remove from local list
    subscriptions.removeWhere((s) => s.id == subscriptionId);

    // Delete from Firestore
    await _firestore.deleteSubscription(subscriptionId);
  }

  /// Toggle subscription active status
  Future<void> toggleSubscription(String id) async {
    final index = subscriptions.indexWhere((s) => s.id == id);
    if (index != -1) {
      subscriptions[index] = subscriptions[index].copyWith(
        isActive: !subscriptions[index].isActive,
      );
      await updateSubscription(subscriptions[index]);
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
        await saveBudget(); // Save alert markers

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
        category: sub.category,
        amountYuan: sub.amountYuan,
        note: 'Subscription: ${sub.name}',
        date: DateTime.now(),
      );

      // Update last billed date
      final updated = sub.copyWith(lastBilledDate: DateTime.now());
      await updateSubscription(updated);
    }
  }

  /// Get monthly subscription total
  double getMonthlySubscriptionTotal() {
    return getActiveSubscriptions()
        .where((s) => s.cycle == SubscriptionCycle.monthly)
        .fold<double>(0, (sum, s) => sum + s.amountYuan);
  }

  Future<void> checkAndNotifySubscriptions() async {
    for (final sub in subscriptions.where((s) => s.isActive)) {
      if (sub.shouldNotify()) {
        final alertKey = '${sub.id}-${sub.getNextBillingDate().toIso8601String().split('T')[0]}';
        if (!_sentSubscriptionAlerts.contains(alertKey)) {
          await NotificationService.I.sendSubscriptionAlert(
            name: sub.name,
            amount: sub.amountYuan,
            daysUntil: sub.getDaysUntilNextBilling(),
          );
          _sentSubscriptionAlerts.add(alertKey);
          await saveSubscriptions();
        }
      }
    }
  }
}

