// Enhanced Weekly Screen with navigation to daily view
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/habit_data_provider.dart';
import '../screens/daily_screen.dart'; // Import the new DailyScreen

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
    final screenSize = MediaQuery.of(context).size;

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
          // Add quick action to go to today's daily view
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Today',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyScreen(initialDate: DateTime.now()),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Week Selector
            _buildWeekSelector(screenSize),

            // Week Overview Card
            _buildWeekOverviewCard(weekEntries, screenSize),

            // Enhanced Daily Progress with tap navigation
            _buildDailyProgress(weekEntries, screenSize),

            // Category Performance
            _buildCategoryPerformance(habitData, weeklyAverages, screenSize),

            SizedBox(height: screenSize.height * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelector(Size screenSize) {
    return Card(
      margin: EdgeInsets.all(screenSize.width * 0.04),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.04,
          vertical: screenSize.height * 0.015,
        ),
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
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${DateFormat('MMM d').format(_weekStart)} - ${DateFormat('MMM d, yyyy').format(_weekEnd)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width < 400 ? 14 : 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenSize.height * 0.005),
                  Text(
                    'Week ${_getWeekNumber()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
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

  Widget _buildWeekOverviewCard(List<DailyEntry> weekEntries, Size screenSize) {
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
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.01,
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          children: [
            Text(
              'Week Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 18 : 22,
              ),
            ),
            SizedBox(height: screenSize.height * 0.025),

            // Responsive layout for stats
            screenSize.width > 600
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildStatItems(
                    weekAverage,
                    daysCompleted,
                    bestDay,
                    screenSize,
                  ),
                )
                : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children:
                          _buildStatItems(
                            weekAverage,
                            daysCompleted,
                            bestDay,
                            screenSize,
                          ).take(2).toList(),
                    ),
                    if (bestDay != null) ...[
                      SizedBox(height: screenSize.height * 0.02),
                      _buildStatItems(
                        weekAverage,
                        daysCompleted,
                        bestDay,
                        screenSize,
                      )[2],
                    ],
                  ],
                ),

            SizedBox(height: screenSize.height * 0.02),
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

  List<Widget> _buildStatItems(
    double weekAverage,
    int daysCompleted,
    DailyEntry? bestDay,
    Size screenSize,
  ) {
    final items = [
      _buildStatItem(
        'Average',
        '${weekAverage.toStringAsFixed(1)}%',
        Icons.trending_up,
        _getPerformanceColor(weekAverage),
        screenSize,
      ),
      _buildStatItem(
        'Days Tracked',
        '$daysCompleted/7',
        Icons.calendar_today,
        daysCompleted >= 5 ? Colors.green : Colors.orange,
        screenSize,
      ),
    ];

    if (bestDay != null) {
      items.add(
        _buildStatItem(
          'Best Day',
          '${bestDay.percentage.toStringAsFixed(1)}%',
          Icons.star,
          Colors.amber,
          screenSize,
          onTap: () => _navigateToDailyView(bestDay.date),
        ),
      );
    }

    return items;
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Size screenSize, {
    VoidCallback? onTap,
  }) {
    final widget = Column(
      children: [
        Icon(icon, color: color, size: screenSize.width < 400 ? 24 : 28),
        SizedBox(height: screenSize.height * 0.01),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: screenSize.width < 400 ? 14 : 16,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: screenSize.width < 400 ? 10 : 12,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.all(8), child: widget),
      );
    }

    return widget;
  }

  // Enhanced Daily Progress with tap navigation
  Widget _buildDailyProgress(List<DailyEntry> weekEntries, Size screenSize) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.01,
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width < 400 ? 16 : 18,
                  ),
                ),
                Text(
                  'Tap to view/edit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: screenSize.width < 400 ? 10 : 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenSize.height * 0.02),
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

                return _buildDayProgress(dayDate, dayEntry, screenSize);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayProgress(DateTime date, DailyEntry entry, Size screenSize) {
    final isToday = _isSameDay(date, DateTime.now());
    final isFuture = date.isAfter(DateTime.now());
    final hasData = entry.itemGrades.isNotEmpty;

    // Responsive circle size
    final circleSize = screenSize.width < 400 ? 35.0 : 40.0;
    final fontSize = screenSize.width < 400 ? 8.0 : 10.0;

    return Flexible(
      child: InkWell(
        onTap: isFuture ? null : () => _navigateToDailyView(date),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: screenSize.width < 400 ? 10 : 12,
                  color: isFuture ? Colors.grey : null,
                ),
              ),
              SizedBox(height: screenSize.height * 0.01),
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isFuture
                          ? Colors.grey.withOpacity(0.1)
                          : hasData
                          ? _getPerformanceColor(
                            entry.percentage,
                          ).withOpacity(0.2)
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
                      isFuture
                          ? Icon(
                            Icons.schedule,
                            size: fontSize + 6,
                            color: Colors.grey,
                          )
                          : hasData
                          ? Text(
                            '${entry.percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: _getPerformanceColor(entry.percentage),
                            ),
                          )
                          : Icon(
                            Icons.add,
                            size: fontSize + 6,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.005),
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: screenSize.width < 400 ? 10 : 12,
                  color: isFuture ? Colors.grey : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation helper
  void _navigateToDailyView(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DailyScreen(initialDate: date)),
    );
  }

  Widget _buildCategoryPerformance(
    HabitDataProvider habitData,
    Map<String, double> weeklyAverages,
    Size screenSize,
  ) {
    return Card(
      margin: EdgeInsets.all(screenSize.width * 0.04),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 16 : 18,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: habitData.categories.length,
              itemBuilder: (context, index) {
                final category = habitData.categories[index];
                final categoryAverage = _calculateCategoryAverage(
                  category,
                  weeklyAverages,
                );

                return Card(
                  margin: EdgeInsets.only(bottom: screenSize.height * 0.01),
                  child: ExpansionTile(
                    leading: Icon(
                      category.icon,
                      color: category.color,
                      size: screenSize.width < 400 ? 20 : 24,
                    ),
                    title: Text(
                      category.nameAr,
                      style: TextStyle(
                        fontSize: screenSize.width < 400 ? 14 : 16,
                      ),
                    ),
                    subtitle: Text(
                      '${categoryAverage.toStringAsFixed(1)}% average',
                      style: TextStyle(
                        fontSize: screenSize.width < 400 ? 12 : 14,
                      ),
                    ),
                    trailing: SizedBox(
                      width: screenSize.width < 400 ? 20 : 24,
                      height: screenSize.width < 400 ? 20 : 24,
                      child: CircularProgressIndicator(
                        value: categoryAverage / 10,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        color: category.color,
                        strokeWidth: screenSize.width < 400 ? 2 : 3,
                      ),
                    ),
                    children:
                        category.items.map((item) {
                          final itemAverage = weeklyAverages[item.id] ?? 0.0;
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.04,
                              vertical: screenSize.height * 0.005,
                            ),
                            title: Text(
                              item.nameAr,
                              style: TextStyle(
                                fontSize: screenSize.width < 400 ? 13 : 15,
                              ),
                            ),
                            subtitle: Text(
                              item.nameEn,
                              style: TextStyle(
                                fontSize: screenSize.width < 400 ? 11 : 13,
                              ),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.02,
                                vertical: screenSize.height * 0.005,
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
                                  fontSize: screenSize.width < 400 ? 12 : 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                );
              },
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
