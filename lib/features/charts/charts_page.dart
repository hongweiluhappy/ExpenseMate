import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_state.dart';
import '../../models/expense.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({super.key});

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  int _selectedIndex = 0; // 0: Week view, 1: Month view

  // Category color mapping
  static const Map<String, Color> _categoryColors = {
    'Food': Color(0xFFFF6B6B),
    'Transport': Color(0xFF4ECDC4),
    'Study': Color(0xFF45B7D1),
    'Entertainment': Color(0xFFFFBE0B),
    'Rent': Color(0xFF95E1D3),
    'Other': Color(0xFFB8B8B8),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Charts'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Week/Month Toggle Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('This Week'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('This Month'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: {_selectedIndex},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedIndex = newSelection.first;
                });
              },
            ),
          ),
          
          // Chart Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bar Chart Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedIndex == 0 ? 'Weekly Daily Expenses' : 'Monthly Daily Expenses',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 250,
                            child: _selectedIndex == 0
                                ? _buildWeeklyBarChart()
                                : _buildMonthlyBarChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pie Chart Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedIndex == 0 ? 'Weekly Category Distribution' : 'Monthly Category Distribution',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildPieChart(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary StatisticsCard
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSummary(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build weekly bar chart
  Widget _buildWeeklyBarChart() {
    final data = _getWeeklyData();
    
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(data.values),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final weekDay = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][group.x.toInt()];
              return BarTooltipItem(
                '$weekDay\n\$${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Day'];
                if (value.toInt() >= 0 && value.toInt() < weekDays.length) {
                  return Text(weekDays[value.toInt()], style: const TextStyle(fontSize: 12));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(data.values),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Theme.of(context).colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Build monthly bar chart
  Widget _buildMonthlyBarChart() {
    final data = _getMonthlyData();
    
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(data.values),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Day ${group.x.toInt() + 1}\n\$${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0 || value.toInt() == 0) {
                  return Text('${value.toInt() + 1}', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Theme.of(context).colorScheme.primary,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Build pie chart
  Widget _buildPieChart() {
    final data = _getCategoryData();

    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final total = data.values.reduce((a, b) => a + b);

    return Column(
      children: [
        // Pie Chart
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: data.entries.map((entry) {
                final percentage = (entry.value / total * 100);
                return PieChartSectionData(
                  color: _categoryColors[entry.key] ?? Colors.grey,
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: data.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _categoryColors[entry.key] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key} \$${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // Build summary statistics
  Widget _buildSummary() {
    final expenses = _selectedIndex == 0 ? _getWeekExpenses() : _getMonthExpenses();
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amountCents / 100);
    final avg = expenses.isEmpty ? 0.0 : total / expenses.length;
    final maxExpense = expenses.isEmpty ? null : expenses.reduce((a, b) => a.amountCents > b.amountCents ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Statistics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildSummaryRow('Total Spending', '\$${total.toStringAsFixed(2)}'),
        _buildSummaryRow('count', '${expenses.length}'),
        _buildSummaryRow('Average per Transaction', '\$${avg.toStringAsFixed(2)}'),
        if (maxExpense != null)
          _buildSummaryRow(
            'Largest Transaction',
            '\$${(maxExpense.amountCents / 100).toStringAsFixed(2)} (${maxExpense.category})',
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Get weekly expenses
  List<Expense> _getWeekExpenses() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStartDate.add(const Duration(days: 7));

    return AppState.I.expenses.where((e) {
      return e.spendDate.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
          e.spendDate.isBefore(weekEnd);
    }).toList();
  }

  // Get monthly expenses
  List<Expense> _getMonthExpenses() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    return AppState.I.expenses.where((e) {
      return e.spendDate.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          e.spendDate.isBefore(monthEnd);
    }).toList();
  }

  // Get weekly data(Group by weekday)
  Map<int, double> _getWeeklyData() {
    final expenses = _getWeekExpenses();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    // Initialize7days data
    final Map<int, double> data = {
      for (int i = 0; i < 7; i++) i: 0.0,
    };

    for (final expense in expenses) {
      final dayIndex = expense.spendDate.difference(weekStartDate).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        data[dayIndex] = (data[dayIndex] ?? 0) + expense.amountCents / 100;
      }
    }

    return data;
  }

  // Get monthly data (Group by Day)
  Map<int, double> _getMonthlyData() {
    final expenses = _getMonthExpenses();
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // Initialize data for all days of the month
    final Map<int, double> data = {
      for (int i = 0; i < daysInMonth; i++) i: 0.0,
    };

    for (final expense in expenses) {
      final dayIndex = expense.spendDate.day - 1;
      if (dayIndex >= 0 && dayIndex < daysInMonth) {
        data[dayIndex] = (data[dayIndex] ?? 0) + expense.amountCents / 100;
      }
    }

    return data;
  }

  // Get category data
  Map<String, double> _getCategoryData() {
    final expenses = _selectedIndex == 0 ? _getWeekExpenses() : _getMonthExpenses();
    final Map<String, double> data = {};

    for (final expense in expenses) {
      data[expense.category] = (data[expense.category] ?? 0) + expense.amountCents / 100;
    }

    return data;
  }

  /// Calculate chart max Y value, Avoid being 0
  double _calculateMaxY(Iterable<double> values) {
    if (values.isEmpty) {
      return 10.0; // Default max value
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return 10.0; // e.g. If max value is 0, return default value
    }

    return maxValue * 1.2; // Leave 20% space
  }

  /// Calculate chart Y Axis interval, Avoid being 0
  double _calculateInterval(Iterable<double> values) {
    if (values.isEmpty) {
      return 1.0; // Default interval
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) {
      return 1.0; // e.g.If max value is 0, Return default interval
    }

    final interval = (maxValue * 1.2) / 5;
    return interval > 0 ? interval : 1.0; // Ensure interval greater than 0
  }
}

