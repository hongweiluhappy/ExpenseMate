import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../models/subscription.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  // CategoryIcons and colors
  static const Map<String, IconData> _categoryIcons = {
    'Rent': Icons.home,
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Study': Icons.school,
    'Entertainment': Icons.movie,
    'Other': Icons.more_horiz,
  };

  static const Map<String, Color> _categoryColors = {
    'Rent': Color(0xFF95E1D3),
    'Food': Color(0xFFFF6B6B),
    'Transport': Color(0xFF4ECDC4),
    'Study': Color(0xFF45B7D1),
    'Entertainment': Color(0xFFFFBE0B),
    'Other': Color(0xFFB8B8B8),
  };

  @override
  void initState() {
    super.initState();
    // Check and process today billings
    _processTodayBillings();
  }

  Future<void> _processTodayBillings() async {
    await AppState.I.processTodayBillings();
    await AppState.I.checkSubscriptionAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscriptions = AppState.I.subscriptions;
    final activeSubscriptions = subscriptions.where((s) => s.isActive).toList();
    final inactiveSubscriptions = subscriptions.where((s) => !s.isActive).toList();
    final monthlyTotal = AppState.I.getMonthlySubscriptionTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await AppState.I.checkSubscriptionAlerts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription reminders checked')),
                );
              }
            },
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Check Reminders',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-subscription').then((_) => setState(() {})),
        icon: const Icon(Icons.add),
        label: const Text('Add Subscription'),
      ),
      body: subscriptions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.subscriptions_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subscription records yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add fixed expenses',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscription Statistics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                theme,
                                'Active Subscriptions',
                                '${activeSubscriptions.length}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                theme,
                                'Monthly Spending',
                                '\$${monthlyTotal.toStringAsFixed(0)}',
                                Icons.payments,
                                theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Active Subscriptions
                if (activeSubscriptions.isNotEmpty) ...[
                  Text(
                    'Active Subscriptions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...activeSubscriptions.map((sub) => _buildSubscriptionCard(theme, sub)),
                  const SizedBox(height: 16),
                ],

                // PausedSubscription
                if (inactiveSubscriptions.isNotEmpty) ...[
                  Text(
                    'Paused',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...inactiveSubscriptions.map((sub) => _buildSubscriptionCard(theme, sub)),
                ],

                const SizedBox(height: 80), // to FAB Leave space
              ],
            ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(ThemeData theme, Subscription sub) {
    final color = _categoryColors[sub.category] ?? Colors.grey;
    final icon = _categoryIcons[sub.category] ?? Icons.help;
    final daysUntil = sub.getDaysUntilNextBilling();
    final nextDate = sub.getNextBillingDate();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          sub.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: sub.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${sub.cycle.displayName} · \$${sub.amountYuan.toStringAsFixed(2)}'),
            const SizedBox(height: 2),
            Text(
              sub.isActive
                  ? 'Next billing: ${DateFormat('MMM d').format(nextDate)} ($daysUntil days)'
                  : 'Paused',
              style: TextStyle(
                color: daysUntil <= 3 && sub.isActive ? Colors.orange : null,
                fontWeight: daysUntil <= 3 && sub.isActive ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, sub),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: const [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(sub.isActive ? Icons.pause : Icons.play_arrow, size: 20),
                  const SizedBox(width: 8),
                  Text(sub.isActive ? 'Pause' : 'Enable'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action, Subscription sub) async {
    switch (action) {
      case 'edit':
        await Navigator.pushNamed(
          context,
          '/add-subscription',
          arguments: sub,
        );
        setState(() {});
        break;

      case 'toggle':
        await AppState.I.toggleSubscription(sub.id);
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sub.isActive ? 'Subscription paused' : 'Subscription enabled'),
            ),
          );
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Confirm delete subscription"${sub.name}"? '),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await AppState.I.deleteSubscription(sub.id);
          setState(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subscription deleted')),
            );
          }
        }
        break;
    }
  }
}

