import 'package:flutter/material.dart';
import '../../models/city_data.dart';
import '../../data/cities_database.dart';

class BudgetRecommendationPage extends StatefulWidget {
  const BudgetRecommendationPage({super.key});

  @override
  State<BudgetRecommendationPage> createState() => _BudgetRecommendationPageState();
}

class _BudgetRecommendationPageState extends State<BudgetRecommendationPage> {
  String? _selectedCity;
  LifestyleLevel _selectedLevel = LifestyleLevel.moderate;
  
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cityData = _selectedCity != null 
        ? CitiesDatabase.getCityByName(_selectedCity!)
        : null;

    return Scaffold(
      appBar: AppBar(
	        title: const Text('Living Expense Recommendation'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select City
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_city, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Select Your City',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Please select your city',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: CitiesDatabase.getCityNames().map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Select Lifestyle
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.style, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Lifestyle',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...LifestyleLevel.values.map((level) {
                      return RadioListTile<LifestyleLevel>(
                        value: level,
                        groupValue: _selectedLevel,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLevel = value;
                            });
                          }
                        },
                        title: Text(level.displayName),
                        subtitle: Text(
                          level.description,
                          style: theme.textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recommendation Results
            if (cityData != null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.recommend, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Recommended Allocation',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${cityData.name} · ${_selectedLevel.displayName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total Budget
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Suggested Monthly Budget',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              '\$${cityData.getTotalBudget(_selectedLevel).toStringAsFixed(0)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Category Allocation
                      ..._categoryIcons.keys.map((category) {
                        final amount = cityData.getCategoryAmount(category, _selectedLevel);
                        final total = cityData.getTotalBudget(_selectedLevel);
                        final percentage = (amount / total * 100);
                        final color = _categoryColors[category] ?? Colors.grey;
                        final icon = _categoryIcons[category] ?? Icons.help;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, size: 20, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${amount.toStringAsFixed(0)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[200],
                                color: color,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),

                      // Apply Budget Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _applyBudget(cityData),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Apply This Budget'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Card
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
                            'Tips',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('📊', 'Data based on city average consumption'),
                      const SizedBox(height: 8),
                      _buildInfoRow('💡', 'Actual spending may vary by individual'),
                      const SizedBox(height: 8),
                      _buildInfoRow('🎯', 'Adjust according to actual situation'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // No city selected prompt
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_searching,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please select a city first',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a city to view recommended allocation',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
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

  void _applyBudget(CityData cityData) {
    final totalBudget = cityData.getTotalBudget(_selectedLevel);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Budget'),
        content: Text(
          'Set monthly budget to \$${totalBudget.toStringAsFixed(0)}? \n\n'
          'This will override current budget settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, totalBudget);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

