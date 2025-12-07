import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_state.dart';
import '../../models/subscription.dart';

class AddSubscriptionPage extends StatefulWidget {
  const AddSubscriptionPage({super.key});

  @override
  State<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _selectedCategory = 'Other';
  SubscriptionCycle _selectedCycle = SubscriptionCycle.monthly;
  int _billingDay = 1;
  bool _isLoading = false;
  Subscription? _editingSubscription;

  static const List<String> _categories = [
    'Rent',
    'Food',
    'Transport',
    'Study',
    'Entertainment',
    'Other',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Rent': Icons.home,
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Study': Icons.school,
    'Entertainment': Icons.movie,
    'Other': Icons.more_horiz,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get subscription to edit (if any)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Subscription && _editingSubscription == null) {
      _editingSubscription = args;
      _nameController.text = args.name;
      _amountController.text = args.amountYuan.toStringAsFixed(2);
      _noteController.text = args.note ?? '';
      _selectedCategory = args.category;
      _selectedCycle = args.cycle;
      _billingDay = args.billingDay;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      if (_editingSubscription != null) {
        // Update existing subscription
        final updated = _editingSubscription!.copyWith(
          name: _nameController.text,
          amountCents: (amount * 100).round(),
          cycle: _selectedCycle,
          billingDay: _billingDay,
          category: _selectedCategory,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
        await AppState.I.updateSubscription(updated);
      } else {
        // Add new subscription
        await AppState.I.addSubscription(
          name: _nameController.text,
          amountYuan: amount,
          cycle: _selectedCycle,
          billingDay: _billingDay,
          category: _selectedCategory,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingSubscription != null ? 'Subscription updated!' : 'Subscription added!'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingSubscription != null ? 'Edit Subscription' : 'Add Subscription'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subscription Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subscription Name',
                  hintText: 'e.g.: Rent、Netflix、Gym membership',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subscription name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Please enter amount',
                  prefixText: '\$ ',
                  suffixText: 'USD',
                  prefixIcon: Icon(Icons.payments),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // CategorySelect
              Text(
                'Category',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIcons[category],
                          size: 18,
                          color: isSelected ? theme.colorScheme.onPrimary : null,
                        ),
                        const SizedBox(width: 4),
                        Text(category),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // WeekPeriod selection
              Text(
                'Billing Cycle',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...SubscriptionCycle.values.map((cycle) {
                return RadioListTile<SubscriptionCycle>(
                  value: cycle,
                  groupValue: _selectedCycle,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCycle = value;
                        // Reset billing day
                        if (value == SubscriptionCycle.weekly) {
                          _billingDay = 1; // Monday
                        } else {
                          _billingDay = 1; // 1
                        }
                      });
                    }
                  },
                  title: Text(cycle.displayName),
                  subtitle: Text(cycle.description),
                  contentPadding: EdgeInsets.zero,
                );
              }),

              const SizedBox(height: 16),

              // Billing DaySelect
              Text(
                _selectedCycle == SubscriptionCycle.weekly ? 'Billing Weekday' : 'Billing Day',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _billingDay,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  helperText: _selectedCycle == SubscriptionCycle.weekly
                      ? 'Select weekly billing day'
                      : 'Select monthly billing day',
                ),
                items: _getBillingDayOptions(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _billingDay = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note(Optional)',
                  hintText: 'Add note information',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // SaveButton
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _saveSubscription,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving...' : 'Save Subscription'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _getBillingDayOptions() {
    if (_selectedCycle == SubscriptionCycle.weekly) {
      // Weekday Options
      return const [
        DropdownMenuItem(value: 1, child: Text('Monday')),
        DropdownMenuItem(value: 2, child: Text('Tuesday')),
        DropdownMenuItem(value: 3, child: Text('Wednesday')),
        DropdownMenuItem(value: 4, child: Text('Thursday')),
        DropdownMenuItem(value: 5, child: Text('Friday')),
        DropdownMenuItem(value: 6, child: Text('Saturday')),
        DropdownMenuItem(value: 7, child: Text('Sunday')),
      ];
    } else {
      // DateOptions(1-31)
      return List.generate(31, (index) {
        final day = index + 1;
        return DropdownMenuItem(
          value: day,
          child: Text('$day '),
        );
      });
    }
  }
}

