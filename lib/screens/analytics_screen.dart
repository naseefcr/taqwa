// Responsive Analytics Screen Implementation
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/habit_data_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTimeRange = 30; // Days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitData = Provider.of<HabitDataProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Insights'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(
                Icons.trending_up,
                size: screenSize.width < 400 ? 20 : 24,
              ),
              text: 'Trends',
            ),
            Tab(
              icon: Icon(
                Icons.pie_chart,
                size: screenSize.width < 400 ? 20 : 24,
              ),
              text: 'Categories',
            ),
            Tab(
              icon: Icon(
                Icons.emoji_events,
                size: screenSize.width < 400 ? 20 : 24,
              ),
              text: 'Achievements',
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 7,
                    child: Row(
                      children: [
                        Icon(
                          Icons.view_week,
                          color:
                              _selectedTimeRange == 7
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Last 7 Days'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 30,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color:
                              _selectedTimeRange == 30
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Last 30 Days'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 90,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color:
                              _selectedTimeRange == 90
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        const Text('Last 90 Days'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrendsTab(habitData, screenSize),
          _buildCategoriesTab(habitData, screenSize),
          _buildAchievementsTab(habitData, screenSize),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(HabitDataProvider habitData, Size screenSize) {
    final trendsData = _getTrendsData(habitData);

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Progress Chart
          _buildOverallProgressChart(trendsData, screenSize),

          SizedBox(height: screenSize.height * 0.03),

          // Streaks Card
          _buildStreaksCard(habitData, screenSize),

          SizedBox(height: screenSize.height * 0.03),

          // Daily Consistency
          _buildConsistencyChart(trendsData, screenSize),

          SizedBox(height: screenSize.height * 0.03),

          // Progress Insights
          _buildProgressInsights(trendsData, screenSize),

          // Bottom padding
          SizedBox(height: screenSize.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildOverallProgressChart(
    List<TrendData> trendsData,
    Size screenSize,
  ) {
    // Responsive chart height
    final chartHeight = screenSize.height < 600 ? 200.0 : 250.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Overall Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width < 400 ? 18 : 22,
                    ),
                  ),
                ),
                Text(
                  'Last $_selectedTimeRange days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: screenSize.width < 400 ? 10 : 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenSize.height * 0.03),
            SizedBox(
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _selectedTimeRange / 7,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final date = DateTime.now().subtract(
                            Duration(days: _selectedTimeRange - value.toInt()),
                          );
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                fontSize: screenSize.width < 400 ? 8 : 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: screenSize.width < 400 ? 35 : 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: screenSize.width < 400 ? 8 : 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: _selectedTimeRange.toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          trendsData
                              .map(
                                (data) => FlSpot(
                                  data.dayIndex.toDouble(),
                                  data.percentage,
                                ),
                              )
                              .toList(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.8),
                          Theme.of(context).colorScheme.primary,
                        ],
                      ),
                      barWidth: screenSize.width < 400 ? 2 : 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaksCard(HabitDataProvider habitData, Size screenSize) {
    final streaks = _calculateStreaks(habitData);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Streaks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 18 : 22,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),

            // Responsive layout for streaks
            screenSize.width > 600
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStreakItem(
                      'Best Streak',
                      '${streaks['bestStreak']} days',
                      Icons.local_fire_department,
                      Colors.orange,
                      screenSize,
                    ),
                    _buildStreakItem(
                      'Current Streak',
                      '${streaks['currentStreak']} days',
                      Icons.flash_on,
                      Colors.blue,
                      screenSize,
                    ),
                    _buildStreakItem(
                      'Total Days',
                      '${streaks['totalDays']} days',
                      Icons.calendar_today,
                      Colors.green,
                      screenSize,
                    ),
                  ],
                )
                : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStreakItem(
                          'Best Streak',
                          '${streaks['bestStreak']} days',
                          Icons.local_fire_department,
                          Colors.orange,
                          screenSize,
                        ),
                        _buildStreakItem(
                          'Current Streak',
                          '${streaks['currentStreak']} days',
                          Icons.flash_on,
                          Colors.blue,
                          screenSize,
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    _buildStreakItem(
                      'Total Days',
                      '${streaks['totalDays']} days',
                      Icons.calendar_today,
                      Colors.green,
                      screenSize,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Size screenSize,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(screenSize.width < 400 ? 10 : 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: screenSize.width < 400 ? 24 : 28,
          ),
        ),
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
  }

  Widget _buildConsistencyChart(List<TrendData> trendsData, Size screenSize) {
    final consistencyData = _getConsistencyData(trendsData);
    final chartHeight = screenSize.height < 600 ? 180.0 : 200.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Consistency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 18 : 22,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            SizedBox(
              height: chartHeight,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Theme.of(context).colorScheme.surface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day =
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][group.x.toInt()];
                        return BarTooltipItem(
                          '$day\n${rod.toY.round()}%',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: screenSize.width < 400 ? 10 : 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              days[value.toInt()],
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                fontSize: screenSize.width < 400 ? 10 : 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: screenSize.width < 400 ? 35 : 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: screenSize.width < 400 ? 8 : 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups:
                      consistencyData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.8),
                                  Theme.of(context).colorScheme.primary,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: screenSize.width < 400 ? 18 : 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(HabitDataProvider habitData, Size screenSize) {
    final categoryData = _getCategoryPerformanceData(habitData);

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      child: Column(
        children: [
          // Category Performance Pie Chart
          _buildCategoryPieChart(categoryData, screenSize),

          SizedBox(height: screenSize.height * 0.03),

          // Category Details
          _buildCategoryDetails(habitData, categoryData, screenSize),

          // Bottom padding
          SizedBox(height: screenSize.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(
    Map<HabitCategory, double> categoryData,
    Size screenSize,
  ) {
    final chartSize = screenSize.height < 600 ? 200.0 : 250.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 18 : 22,
              ),
            ),
            SizedBox(height: screenSize.height * 0.03),
            SizedBox(
              height: chartSize,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: screenSize.width < 400 ? 40 : 50,
                  sections:
                      categoryData.entries.map((entry) {
                        final category = entry.key;
                        final performance = entry.value;
                        return PieChartSectionData(
                          color: category.color,
                          value: performance,
                          title: '${performance.toStringAsFixed(1)}%',
                          radius: screenSize.width < 400 ? 70 : 80,
                          titleStyle: TextStyle(
                            fontSize: screenSize.width < 400 ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Wrap(
              spacing: screenSize.width * 0.04,
              runSpacing: screenSize.height * 0.01,
              children:
                  categoryData.entries.map((entry) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: entry.key.color,
                        ),
                        SizedBox(width: screenSize.width * 0.01),
                        Text(
                          entry.key.nameEn,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontSize: screenSize.width < 400 ? 10 : 12,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDetails(
    HabitDataProvider habitData,
    Map<HabitCategory, double> categoryData,
    Size screenSize,
  ) {
    return Column(
      children:
          categoryData.entries.map((entry) {
            final category = entry.key;
            final performance = entry.value;

            return Card(
              margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.04,
                  vertical: screenSize.height * 0.01,
                ),
                leading: Icon(
                  category.icon,
                  color: category.color,
                  size: screenSize.width < 400 ? 28 : 32,
                ),
                title: Text(
                  category.nameAr,
                  style: TextStyle(fontSize: screenSize.width < 400 ? 14 : 16),
                ),
                subtitle: Text(
                  category.nameEn,
                  style: TextStyle(fontSize: screenSize.width < 400 ? 12 : 14),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${performance.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: category.color,
                        fontSize: screenSize.width < 400 ? 14 : 16,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.005),
                    Container(
                      width: screenSize.width < 400 ? 50 : 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: performance / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: category.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAchievementsTab(HabitDataProvider habitData, Size screenSize) {
    final achievements = _getAchievements(habitData);

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      child: Column(
        children: [
          // Achievement Stats
          _buildAchievementStats(achievements, screenSize),

          SizedBox(height: screenSize.height * 0.03),

          // Achievement List
          ...achievements.map(
            (achievement) => _buildAchievementCard(achievement, screenSize),
          ),

          // Bottom padding
          SizedBox(height: screenSize.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildAchievementStats(
    List<Achievement> achievements,
    Size screenSize,
  ) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 18 : 22,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            SizedBox(
              width: screenSize.width < 400 ? 80 : 100,
              height: screenSize.width < 400 ? 80 : 100,
              child: CircularProgressIndicator(
                value: unlockedCount / totalCount,
                strokeWidth: screenSize.width < 400 ? 6 : 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            Text(
              '$unlockedCount / $totalCount',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 20 : 24,
              ),
            ),
            Text(
              'Achievements Unlocked',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: screenSize.width < 400 ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, Size screenSize) {
    return Card(
      margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.04,
          vertical: screenSize.height * 0.01,
        ),
        leading: Container(
          padding: EdgeInsets.all(screenSize.width < 400 ? 6 : 8),
          decoration: BoxDecoration(
            color:
                achievement.isUnlocked
                    ? achievement.color.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            achievement.icon,
            color:
                achievement.isUnlocked
                    ? achievement.color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
            size: screenSize.width < 400 ? 20 : 24,
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                achievement.isUnlocked
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: screenSize.width < 400 ? 14 : 16,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(fontSize: screenSize.width < 400 ? 12 : 14),
        ),
        trailing: Icon(
          achievement.isUnlocked ? Icons.check_circle : Icons.lock,
          color:
              achievement.isUnlocked
                  ? achievement.color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
          size: screenSize.width < 400 ? 20 : 24,
        ),
      ),
    );
  }

  Widget _buildProgressInsights(List<TrendData> trendsData, Size screenSize) {
    final insights = _generateInsights(trendsData);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights & Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width < 400 ? 18 : 22,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            ...insights.map(
              (insight) => Padding(
                padding: EdgeInsets.only(bottom: screenSize.height * 0.015),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      insight.icon,
                      color: insight.color,
                      size: screenSize.width < 400 ? 18 : 20,
                    ),
                    SizedBox(width: screenSize.width * 0.03),
                    Expanded(
                      child: Text(
                        insight.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: screenSize.width < 400 ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for data processing (same as before)
  List<TrendData> _getTrendsData(HabitDataProvider habitData) {
    final now = DateTime.now();
    final data = <TrendData>[];

    for (int i = 0; i < _selectedTimeRange; i++) {
      final date = now.subtract(Duration(days: _selectedTimeRange - 1 - i));
      final entry = habitData.entries.firstWhere(
        (e) => _isSameDay(e.date, date),
        orElse: () => DailyEntry(date: date, itemGrades: {}, percentage: 0),
      );
      data.add(
        TrendData(dayIndex: i, percentage: entry.percentage, date: date),
      );
    }

    return data;
  }

  List<double> _getConsistencyData(List<TrendData> trendsData) {
    final weekdayData = List.generate(7, (index) => <double>[]);

    for (final data in trendsData) {
      final weekday = data.date.weekday - 1; // Monday = 0
      weekdayData[weekday].add(data.percentage);
    }

    return weekdayData.map((dayData) {
      if (dayData.isEmpty) return 0.0;
      return dayData.reduce((a, b) => a + b) / dayData.length;
    }).toList();
  }

  Map<String, int> _calculateStreaks(HabitDataProvider habitData) {
    final entries =
        habitData.entries.toList()..sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    DateTime? lastDate;

    for (final entry in entries) {
      if (entry.percentage >= 70) {
        // Consider 70%+ as a good day
        if (lastDate == null || entry.date.difference(lastDate).inDays == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
        bestStreak = tempStreak > bestStreak ? tempStreak : bestStreak;

        // Check if this continues to today
        if (_isSameDay(entry.date, DateTime.now()) ||
            entry.date.difference(DateTime.now()).inDays == -1) {
          currentStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
      lastDate = entry.date;
    }

    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'totalDays': entries.length,
    };
  }

  Map<HabitCategory, double> _getCategoryPerformanceData(
    HabitDataProvider habitData,
  ) {
    final now = DateTime.now();
    final recentEntries =
        habitData.entries.where((entry) {
          return entry.date.isAfter(
            now.subtract(Duration(days: _selectedTimeRange)),
          );
        }).toList();

    final categoryData = <HabitCategory, double>{};

    for (final category in habitData.categories) {
      final categoryValues = <double>[];

      for (final entry in recentEntries) {
        final categoryItemValues = <int>[];

        for (final item in category.items) {
          final gradeSymbol = entry.itemGrades[item.id];
          if (gradeSymbol != null) {
            final grade = Grade.allGrades.firstWhere(
              (g) => g.symbol == gradeSymbol,
              orElse: () => Grade.allGrades.last,
            );
            categoryItemValues.add(grade.value);
          }
        }

        if (categoryItemValues.isNotEmpty) {
          final average =
              categoryItemValues.reduce((a, b) => a + b) /
              categoryItemValues.length;
          categoryValues.add((average / 10) * 100);
        }
      }

      if (categoryValues.isNotEmpty) {
        categoryData[category] =
            categoryValues.reduce((a, b) => a + b) / categoryValues.length;
      } else {
        categoryData[category] = 0.0;
      }
    }

    return categoryData;
  }

  List<Achievement> _getAchievements(HabitDataProvider habitData) {
    final streaks = _calculateStreaks(habitData);
    final entries = habitData.entries;
    final perfectDays = entries.where((e) => e.percentage == 100).length;

    return [
      Achievement(
        title: 'First Step',
        description: 'Complete your first day',
        icon: Icons.baby_changing_station,
        color: Colors.blue,
        isUnlocked: entries.isNotEmpty,
      ),
      Achievement(
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        isUnlocked:
            streaks['currentStreak']! >= 7 || streaks['bestStreak']! >= 7,
      ),
      Achievement(
        title: 'Perfect Day',
        description: 'Achieve 100% completion',
        icon: Icons.star,
        color: Colors.amber,
        isUnlocked: perfectDays > 0,
      ),
      Achievement(
        title: 'Consistency Master',
        description: 'Track for 30 consecutive days',
        icon: Icons.emoji_events,
        color: Colors.purple,
        isUnlocked: streaks['bestStreak']! >= 30,
      ),
      Achievement(
        title: 'Habit Builder',
        description: 'Complete 100 total days',
        icon: Icons.construction,
        color: Colors.brown,
        isUnlocked: entries.length >= 100,
      ),
      Achievement(
        title: 'Excellence',
        description: 'Achieve 10 perfect days',
        icon: Icons.diamond,
        color: Colors.cyan,
        isUnlocked: perfectDays >= 10,
      ),
    ];
  }

  List<Insight> _generateInsights(List<TrendData> trendsData) {
    final insights = <Insight>[];

    if (trendsData.length >= 7) {
      final recentWeek = trendsData.skip(trendsData.length - 7).toList();
      final averageThisWeek =
          recentWeek.map((e) => e.percentage).reduce((a, b) => a + b) / 7;

      if (averageThisWeek > 80) {
        insights.add(
          Insight(
            text: 'Excellent work! Your consistency this week is outstanding.',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        );
      } else if (averageThisWeek < 50) {
        insights.add(
          Insight(
            text: 'Consider focusing on 2-3 key habits to build momentum.',
            icon: Icons.lightbulb,
            color: Colors.orange,
          ),
        );
      }
    }

    // Find best performing day of week
    final weekdayPerformance = _getConsistencyData(trendsData);
    final bestDayIndex = weekdayPerformance.indexOf(
      weekdayPerformance.reduce((a, b) => a > b ? a : b),
    );
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    insights.add(
      Insight(
        text:
            'Your strongest day is ${dayNames[bestDayIndex]}. Try to replicate this success on other days.',
        icon: Icons.calendar_today,
        color: Colors.blue,
      ),
    );

    return insights;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Helper classes (same as before)
class TrendData {
  final int dayIndex;
  final double percentage;
  final DateTime date;

  TrendData({
    required this.dayIndex,
    required this.percentage,
    required this.date,
  });
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}

class Insight {
  final String text;
  final IconData icon;
  final Color color;

  Insight({required this.text, required this.icon, required this.color});
}
