import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';

class BudgetSettingsPage extends StatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  State<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends State<BudgetSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load current budget
    if (AppState.I.monthlyBudgetCents != null) {
      _budgetController.text = (AppState.I.monthlyBudgetCents! / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final budget = double.parse(_budgetController.text);
      await AppState.I.setMonthlyBudget(budget);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Confirm delete monthly budget settings?'),
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
      setState(() => _isLoading = true);
      try {
        AppState.I.monthlyBudgetCents = null;
        await AppState.I.saveBudget();
        _budgetController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Budget deleted'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentBudget = AppState.I.monthlyBudgetCents;
    final spending = AppState.I.getMonthlySpending();
    final percentage = AppState.I.getBudgetUsagePercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Settings'),
        centerTitle: true,
        actions: [
          if (currentBudget != null)
            IconButton(
              onPressed: _isLoading ? null : _clearBudget,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Budget',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Budget Status Card
              if (currentBudget != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Budget Usage',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Progress Bar
                        LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          color: percentage >= 100
                              ? Colors.red
                              : percentage >= 80
                                  ? Colors.orange
                                  : Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 12),
                        
                        // Statistics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spent',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  '\$${spending.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Budget',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  '\$${(currentBudget / 100).toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Usage Percentage
                        Center(
                          child: Text(
                            'Used ${percentage.toStringAsFixed(1)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: percentage >= 100
                                  ? Colors.red
                                  : percentage >= 80
                                      ? Colors.orange
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Budget SettingsForm
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Monthly Budget',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Budget Amount',
                          hintText: 'Please enter monthly budget amount',
                          prefixText: '\$ ',
                          suffixText: 'USD',
                          border: OutlineInputBorder(),
                          helperText: 'After setting, you will receive reminders at 80% and 100%',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter budget amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _saveBudget,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? 'Saving...' : 'Save Budget'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Reminder Info Card
              Card(
                elevation: 1,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Budget Alert Description',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('⚡', 'When spending reaches 80%, you will receive first reminder'),
                      const SizedBox(height: 8),
                      _buildInfoRow('⚠️', 'When spending reaches 100%, you will receive second reminder'),
                      const SizedBox(height: 8),
                      _buildInfoRow('🔔', 'Each threshold will only alert once per month'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

