// Weekly Screen Implementation
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/habit_data_provider.dart';

class WeeklyScreen extends StatefulWidget {
  const WeeklyScreen({super.key});

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  DateTime _selectedWeek = DateTime.now();

  DateTime get _weekStart {
    final now = _selectedWeek;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  @override
  Widget build(BuildContext context) {
    final habitData = Provider.of<HabitDataProvider>(context);
    final weekEntries = habitData.getWeekEntries(_weekStart);
    final weeklyAverages = habitData.getWeeklyAverages(_weekStart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Analysis'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedWeek = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Selector
          _buildWeekSelector(),

          // Week Overview Card
          _buildWeekOverviewCard(weekEntries),

          // Daily Progress
          _buildDailyProgress(weekEntries),

          // Category Performance
          Expanded(child: _buildCategoryPerformance(habitData, weeklyAverages)),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedWeek = _selectedWeek.subtract(
                    const Duration(days: 7),
                  );
                });
              },
            ),
            Column(
              children: [
                Text(
                  '${DateFormat('MMM d').format(_weekStart)} - ${DateFormat('MMM d, yyyy').format(_weekEnd)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Week ${_getWeekNumber()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedWeek = _selectedWeek.add(const Duration(days: 7));
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekOverviewCard(List<DailyEntry> weekEntries) {
    final weekAverage =
        weekEntries.isNotEmpty
            ? weekEntries.map((e) => e.percentage).reduce((a, b) => a + b) /
                weekEntries.length
            : 0.0;

    final bestDay =
        weekEntries.isNotEmpty
            ? weekEntries.reduce((a, b) => a.percentage > b.percentage ? a : b)
            : null;

    final daysCompleted = weekEntries.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Week Performance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Average',
                  '${weekAverage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  _getPerformanceColor(weekAverage),
                ),
                _buildStatItem(
                  'Days Tracked',
                  '$daysCompleted/7',
                  Icons.calendar_today,
                  daysCompleted >= 5 ? Colors.green : Colors.orange,
                ),
                if (bestDay != null)
                  _buildStatItem(
                    'Best Day',
                    '${bestDay.percentage.toStringAsFixed(1)}%',
                    Icons.star,
                    Colors.amber,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: weekAverage / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: _getPerformanceColor(weekAverage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDailyProgress(List<DailyEntry> weekEntries) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final dayDate = _weekStart.add(Duration(days: index));
                final dayEntry = weekEntries.firstWhere(
                  (entry) => _isSameDay(entry.date, dayDate),
                  orElse:
                      () => DailyEntry(
                        date: dayDate,
                        itemGrades: {},
                        percentage: 0,
                      ),
                );

                return _buildDayProgress(dayDate, dayEntry);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayProgress(DateTime date, DailyEntry entry) {
    final isToday = _isSameDay(date, DateTime.now());
    final hasData = entry.itemGrades.isNotEmpty;

    return Column(
      children: [
        Text(
          DateFormat('E').format(date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                hasData
                    ? _getPerformanceColor(entry.percentage).withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceVariant,
            border:
                isToday
                    ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                    : null,
          ),
          child: Center(
            child:
                hasData
                    ? Text(
                      '${entry.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPerformanceColor(entry.percentage),
                      ),
                    )
                    : Icon(
                      Icons.remove,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Text('${date.day}', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCategoryPerformance(
    HabitDataProvider habitData,
    Map<String, double> weeklyAverages,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: habitData.categories.length,
                itemBuilder: (context, index) {
                  final category = habitData.categories[index];
                  final categoryAverage = _calculateCategoryAverage(
                    category,
                    weeklyAverages,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: Icon(category.icon, color: category.color),
                      title: Text(category.nameAr),
                      subtitle: Text(
                        '${categoryAverage.toStringAsFixed(1)}% average',
                      ),
                      trailing: CircularProgressIndicator(
                        value: categoryAverage / 10,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        color: category.color,
                      ),
                      children:
                          category.items.map((item) {
                            final itemAverage = weeklyAverages[item.id] ?? 0.0;
                            return ListTile(
                              title: Text(item.nameAr),
                              subtitle: Text(item.nameEn),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getGradeColor(
                                    itemAverage,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${itemAverage.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    color: _getGradeColor(itemAverage),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateCategoryAverage(
    HabitCategory category,
    Map<String, double> weeklyAverages,
  ) {
    if (category.items.isEmpty) return 0.0;

    final categoryValues =
        category.items
            .map((item) => weeklyAverages[item.id] ?? 0.0)
            .where((value) => value > 0)
            .toList();

    if (categoryValues.isEmpty) return 0.0;

    return categoryValues.reduce((a, b) => a + b) / categoryValues.length;
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(double value) {
    if (value >= 9) return Colors.green.shade700;
    if (value >= 8) return Colors.green.shade600;
    if (value >= 7) return Colors.lightGreen.shade600;
    if (value >= 6) return Colors.lightGreen.shade500;
    if (value >= 5) return Colors.orange.shade600;
    if (value >= 4) return Colors.orange.shade500;
    if (value > 0) return Colors.red.shade400;
    return Colors.red.shade600;
  }

  int _getWeekNumber() {
    final dayOfYear =
        _weekStart.difference(DateTime(_weekStart.year, 1, 1)).inDays;
    return (dayOfYear / 7).ceil();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
