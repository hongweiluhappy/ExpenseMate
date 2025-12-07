import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/auth_service.dart';
import '../../models/expense.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Category icon mapping
  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Study': Icons.school,
    'Entertainment': Icons.movie,
    'Rent': Icons.home,
    'Other': Icons.more_horiz,
  };

  // Category color mapping
  static const Map<String, Color> _categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Study': Colors.green,
    'Entertainment': Colors.purple,
    'Rent': Colors.red,
    'Other': Colors.grey,
  };

  // Calculate monthly total
  double _getMonthTotal() {
    final now = DateTime.now();
    return AppState.I.expenses
        .where((e) => e.spendDate.year == now.year && e.spendDate.month == now.month)
        .fold<double>(0, (sum, e) => sum + e.amountCents / 100);
  }

  // Calculate today total
  double _getTodayTotal() {
    final now = DateTime.now();
    return AppState.I.expenses
        .where((e) =>
            e.spendDate.year == now.year &&
            e.spendDate.month == now.month &&
            e.spendDate.day == now.day)
        .fold<double>(0, (sum, e) => sum + e.amountCents / 100);
  }

  // Calculate monthly spending by category
  Map<String, double> _getCategoryTotals() {
    final now = DateTime.now();
    final monthExpenses = AppState.I.expenses
        .where((e) => e.spendDate.year == now.year && e.spendDate.month == now.month);

    final Map<String, double> totals = {};
    for (final expense in monthExpenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amountCents / 100;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Expense> list = List.of(AppState.I.expenses)
      ..sort((a, b) => b.spendDate.compareTo(a.spendDate));

    final monthTotal = _getMonthTotal();
    final todayTotal = _getTodayTotal();
    final categoryTotals = _getCategoryTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpenseMate'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final budget = await Navigator.pushNamed(context, '/budget-recommendation');
              if (budget != null && budget is double && mounted) {
                await AppState.I.setMonthlyBudget(budget);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Budget set to \$${budget.toStringAsFixed(0)}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Budget Recommendation',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/budget-settings').then((_) => setState(() {})),
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Budget Settings',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/charts').then((_) => setState(() {})),
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Expense Charts',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/subscriptions').then((_) => setState(() {})),
            icon: const Icon(Icons.subscriptions),
            tooltip: 'Subscriptions',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/jobs').then((_) => setState(() {})),
            icon: const Icon(Icons.work_outline),
            tooltip: 'Part-time Jobs',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Account',
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await AuthService.I.signOut();
                  // Navigation will be handled by AuthWrapper
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 12),
                    Text(AuthService.I.currentUser?.displayName ?? 'User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'email',
                enabled: false,
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      AuthService.I.currentUser?.email ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-expense').then((_) => setState(() {})),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expense records yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add your first expense',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Statistics Card
                SliverToBoxAdapter(
                  child: Container(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // This Month and Today Statistics
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Monthly Spending',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${monthTotal.toStringAsFixed(2)}',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Today's Spending",
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${todayTotal.toStringAsFixed(2)}',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Budget Progress Card
                        if (AppState.I.monthlyBudgetCents != null) ...[
                          const SizedBox(height: 12),
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Monthly Budget',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => Navigator.pushNamed(context, '/budget-settings')
                                            .then((_) => setState(() {})),
                                        icon: const Icon(Icons.settings, size: 16),
                                        label: const Text('Settings'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Budget Progress Bar
                                  Builder(
                                    builder: (context) {
                                      final percentage = AppState.I.getBudgetUsagePercentage();
                                      final remaining = AppState.I.getRemainingBudget();
                                      final budget = AppState.I.monthlyBudgetCents! / 100;

                                      return Column(
                                        children: [
                                          LinearProgressIndicator(
                                            value: percentage / 100,
                                            minHeight: 10,
                                            backgroundColor: Colors.grey[200],
                                            color: percentage >= 100
                                                ? Colors.red
                                                : percentage >= 80
                                                    ? Colors.orange
                                                    : Colors.green,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Used',
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    '${percentage.toStringAsFixed(1)}%',
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: percentage >= 100
                                                          ? Colors.red
                                                          : percentage >= 80
                                                              ? Colors.orange
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Remaining Budget',
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                  Text(
                                                    '\$${remaining.toStringAsFixed(2)}',
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Total budget: \$${budget.toStringAsFixed(2)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Subscription StatisticsCard
                        if (AppState.I.subscriptions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Card(
                            elevation: 3,
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/subscriptions').then((_) => setState(() {})),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Builder(
                                  builder: (context) {
                                    final activeCount = AppState.I.getActiveSubscriptions().length;
                                    final monthlyTotal = AppState.I.getMonthlySubscriptionTotal();
                                    final upcoming = AppState.I.getUpcomingSubscriptions();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.subscriptions,
                                                  color: theme.colorScheme.primary,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Subscriptions',
                                                  style: theme.textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Active Subscriptions',
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$activeCount ',
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Monthly Spending',
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '\$${monthlyTotal.toStringAsFixed(0)}',
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.secondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (upcoming.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.notifications_active,
                                                  color: Colors.orange,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${upcoming.length} subscriptions due soon',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: Colors.orange.shade900,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],

                        // CategoryStatistics
                        if (categoryTotals.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Spending by Category',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...categoryTotals.entries.map((entry) {
                                    final percentage = monthTotal > 0
                                        ? (entry.value / monthTotal * 100)
                                        : 0.0;
                                    final color = _categoryColors[entry.key] ?? Colors.grey;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _categoryIcons[entry.key],
                                            size: 20,
                                            color: color,
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 50,
                                            child: Text(
                                              entry.key,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: percentage / 100,
                                              backgroundColor: color.withOpacity(0.2),
                                              valueColor: AlwaysStoppedAnimation<Color>(color),
                                              minHeight: 8,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 80,
                                            child: Text(
                                              '\$${entry.value.toStringAsFixed(2)}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Expense List Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Recent Expenses',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total ${list.length} items',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expense List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final e = list[index];
                        final color = _categoryColors[e.category] ?? Colors.grey;
                        final icon = _categoryIcons[e.category] ?? Icons.more_horiz;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.2),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  e.category,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                if (e.note != null && e.note!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      e.note!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, y').format(e.spendDate),
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: Text(
                              '\$${(e.amountCents / 100).toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                ),

                // Bottom Spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
    );
  }
}