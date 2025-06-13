// Enhanced TodayScreen -> DailyScreen with date navigation
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/habit_data_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_sync_service.dart';

class DailyScreen extends StatefulWidget {
  final DateTime? initialDate;

  const DailyScreen({super.key, this.initialDate});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late DateTime _selectedDate;
  final Map<String, String> _currentGrades = {};
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadEntryForDate();
  }

  void _loadEntryForDate() {
    final habitData = Provider.of<HabitDataProvider>(context, listen: false);
    final entry = habitData.entries.firstWhere(
      (entry) => _isSameDay(entry.date, _selectedDate),
      orElse:
          () => DailyEntry(date: _selectedDate, itemGrades: {}, percentage: 0),
    );

    setState(() {
      _currentGrades.clear();
      _currentGrades.addAll(entry.itemGrades);
      _hasUnsavedChanges = false;
    });
  }

  void _navigateToDate(DateTime newDate) {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog(() {
        setState(() {
          _selectedDate = newDate;
        });
        _loadEntryForDate();
      });
    } else {
      setState(() {
        _selectedDate = newDate;
      });
      _loadEntryForDate();
    }
  }

  void _showUnsavedChangesDialog(VoidCallback onProceed) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes for this day. Do you want to save them before navigating?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onProceed();
                },
                child: const Text('Discard Changes'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveDayEntry();
                  onProceed();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Save & Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveDayEntry() async {
    final habitData = Provider.of<HabitDataProvider>(context, listen: false);
    await habitData.saveDayEntry(_selectedDate, _currentGrades);
    setState(() {
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      final dayName =
          _isSameDay(_selectedDate, DateTime.now())
              ? 'Today'
              : DateFormat('MMM d').format(_selectedDate);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $dayName saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _isToday => _isSameDay(_selectedDate, DateTime.now());
  bool get _isFutureDate => _selectedDate.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final habitData = Provider.of<HabitDataProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final syncService = Provider.of<FirestoreSyncService>(context);
    final hijriDate = HijriCalendar.fromDate(_selectedDate);
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) {
        if (!didPop && _hasUnsavedChanges) {
          _showUnsavedChangesDialog(() => Navigator.of(context).pop());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                _isToday
                    ? 'Today'
                    : DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear} هـ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                () => _navigateToDate(
                  _selectedDate.subtract(const Duration(days: 1)),
                ),
          ),
          actions: [
            // Date picker button
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _showDatePicker(),
            ),

            // Next day button (only if not future date)
            if (!_isFutureDate)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    () => _navigateToDate(
                      _selectedDate.add(const Duration(days: 1)),
                    ),
              ),

            // Sync indicator
            if (syncService.isSyncing)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

            // Entry method selector
            PopupMenuButton<String>(
              icon: const Icon(Icons.view_module),
              onSelected: (value) {
                habitData.setEntryMethod(value);
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'grid',
                      child: Row(
                        children: [
                          Icon(
                            Icons.grid_view,
                            color:
                                habitData.currentEntryMethod == 'grid'
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          const Text('Grid View'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'list',
                      child: Row(
                        children: [
                          Icon(
                            Icons.list,
                            color:
                                habitData.currentEntryMethod == 'list'
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          const Text('List View'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'card',
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_membership,
                            color:
                                habitData.currentEntryMethod == 'card'
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          const Text('Card View'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'swipe',
                      child: Row(
                        children: [
                          Icon(
                            Icons.swipe,
                            color:
                                habitData.currentEntryMethod == 'swipe'
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          const Text('Swipe View'),
                        ],
                      ),
                    ),
                  ],
            ),

            // Theme toggle
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Date navigation and status card
            _buildDateStatusCard(habitData, screenSize),

            // Entry Method Views
            Expanded(child: _buildEntryView(habitData, screenSize)),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildDateStatusCard(HabitDataProvider habitData, Size screenSize) {
    final todayPercentage = habitData.calculateDayPercentage(_currentGrades);
    final hasExistingEntry = habitData.entries.any(
      (entry) => _isSameDay(entry.date, _selectedDate),
    );

    return Container(
      margin: EdgeInsets.all(screenSize.width * 0.04),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Column(
            children: [
              // Date navigation row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quick date buttons
                  if (!_isToday)
                    TextButton.icon(
                      onPressed: () => _navigateToDate(DateTime.now()),
                      icon: const Icon(Icons.today, size: 16),
                      label: const Text('Today'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),

                  const Spacer(),

                  // Date status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDateStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getDateStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDateStatusIcon(),
                          size: 16,
                          color: _getDateStatusColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDateStatusText(),
                          style: TextStyle(
                            color: _getDateStatusColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenSize.height * 0.02),

              // Progress row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isToday ? 'Today\'s Progress' : 'Day Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_hasUnsavedChanges)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Unsaved changes',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        SizedBox(height: screenSize.height * 0.01),
                        LinearProgressIndicator(
                          value: todayPercentage / 100,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                          color: _getProgressColor(todayPercentage),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenSize.width * 0.04),
                  Column(
                    children: [
                      Text(
                        '${todayPercentage.toStringAsFixed(1)}%',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(todayPercentage),
                        ),
                      ),
                      Text(
                        '${_currentGrades.length}/${_getTotalItems(habitData)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDateStatusColor() {
    if (_isFutureDate) return Colors.blue;
    if (_isToday) return Colors.green;
    return Colors.grey;
  }

  IconData _getDateStatusIcon() {
    if (_isFutureDate) return Icons.schedule;
    if (_isToday) return Icons.today;
    return Icons.history;
  }

  String _getDateStatusText() {
    if (_isFutureDate) return 'Future';
    if (_isToday) return 'Today';

    final daysDifference = DateTime.now().difference(_selectedDate).inDays;
    if (daysDifference == 1) return 'Yesterday';
    return '$daysDifference days ago';
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget? _buildFloatingActionButton() {
    if (_isFutureDate) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.grey,
        icon: const Icon(Icons.block),
        label: const Text('Future Date'),
      );
    }

    if (_currentGrades.isNotEmpty || _hasUnsavedChanges) {
      return FloatingActionButton.extended(
        onPressed: _saveDayEntry,
        icon: const Icon(Icons.save),
        label: Text(_isToday ? 'Save Day' : 'Save Entry'),
        backgroundColor: _hasUnsavedChanges ? Colors.orange : null,
      );
    }

    return null;
  }

  Future<void> _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Select Date to View/Edit',
    );

    if (pickedDate != null) {
      _navigateToDate(pickedDate);
    }
  }

  int _getTotalItems(HabitDataProvider habitData) {
    return habitData.categories
        .map((cat) => cat.items.length)
        .reduce((a, b) => a + b);
  }

  Widget _buildEntryView(HabitDataProvider habitData, Size screenSize) {
    switch (habitData.currentEntryMethod) {
      case 'grid':
        return _buildGridView(habitData, screenSize);
      case 'list':
        return _buildListView(habitData, screenSize);
      case 'card':
        return _buildCardView(habitData, screenSize);
      case 'swipe':
        return _buildSwipeView(habitData, screenSize);
      default:
        return _buildGridView(habitData, screenSize);
    }
  }

  // Update the habit item card to use _currentGrades instead of _todayGrades
  Widget _buildHabitItemCard(HabitItem item, Size screenSize) {
    final currentGrade = _currentGrades[item.id];

    return Card(
      elevation: currentGrade != null ? 4 : 1,
      color:
          currentGrade != null
              ? Grade.allGrades
                  .firstWhere((g) => g.symbol == currentGrade)
                  .color
                  .withOpacity(0.1)
              : null,
      child: InkWell(
        onTap: _isFutureDate ? null : () => _showGradeDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: _isFutureDate ? 0.5 : 1.0,
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.03),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    item.nameAr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width < 400 ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                Flexible(
                  child: Text(
                    item.nameEn,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: screenSize.width < 400 ? 10 : 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (currentGrade != null) ...[
                  SizedBox(height: screenSize.height * 0.01),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.02,
                      vertical: screenSize.height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Grade.allGrades
                              .firstWhere((g) => g.symbol == currentGrade)
                              .color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentGrade,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: screenSize.width < 400 ? 10 : 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGradeDialog(HabitItem item) {
    if (_isFutureDate) return;

    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Column(
              children: [
                Text(item.nameAr),
                Text(
                  item.nameEn,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            content: Wrap(
              spacing: screenSize.width * 0.02,
              runSpacing: screenSize.height * 0.01,
              children:
                  Grade.allGrades.map((grade) {
                    return FilterChip(
                      label: Text('${grade.symbol} (${grade.value})'),
                      selected: _currentGrades[item.id] == grade.symbol,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _currentGrades[item.id] = grade.symbol;
                          } else {
                            _currentGrades.remove(item.id);
                          }
                          _hasUnsavedChanges = true;
                        });
                        Navigator.pop(context);
                      },
                      backgroundColor: grade.color.withOpacity(0.1),
                      selectedColor: grade.color.withOpacity(0.3),
                    );
                  }).toList(),
            ),
            actions: [
              if (_currentGrades[item.id] != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentGrades.remove(item.id);
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Remove'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  // Copy all other view methods (_buildGridView, _buildListView, etc.)
  // from your original TodayScreen but update them to use _currentGrades
  // instead of _todayGrades

  Widget _buildGridView(HabitDataProvider habitData, Size screenSize) {
    final horizontalPadding = screenSize.width * 0.04;
    final verticalPadding = screenSize.height * 0.02;
    final cardMargin = screenSize.height * 0.02;
    final cardPadding = screenSize.width * 0.04;

    int crossAxisCount = screenSize.width > 600 ? 3 : 2;
    double childAspectRatio = screenSize.width > 600 ? 2.5 : 2.2;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      itemCount: habitData.categories.length,
      itemBuilder: (context, index) {
        final category = habitData.categories[index];
        return Card(
          margin: EdgeInsets.only(bottom: cardMargin),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(category.icon, color: category.color),
                    SizedBox(width: screenSize.width * 0.02),
                    Expanded(
                      child: Text(
                        category.nameAr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (screenSize.width > 350) Text(' • ${category.nameEn}'),
                  ],
                ),
                SizedBox(height: screenSize.height * 0.02),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: screenSize.width * 0.02,
                    mainAxisSpacing: screenSize.height * 0.01,
                  ),
                  itemCount: category.items.length,
                  itemBuilder: (context, itemIndex) {
                    final item = category.items[itemIndex];
                    return _buildHabitItemCard(item, screenSize);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add other view methods here (list, card, swipe)...
  Widget _buildListView(HabitDataProvider habitData, Size screenSize) {
    final allItems = habitData.categories.expand((cat) => cat.items).toList();

    return ListView.builder(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        final category = habitData.categories.firstWhere(
          (cat) => cat.id == item.categoryId,
        );

        return Card(
          margin: EdgeInsets.only(bottom: screenSize.height * 0.01),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.04,
              vertical: screenSize.height * 0.01,
            ),
            leading: CircleAvatar(
              backgroundColor: category.color.withOpacity(0.1),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            title: Text(item.nameAr),
            subtitle: Text(item.nameEn),
            trailing: _buildGradeSelector(item.id),
            onTap: _isFutureDate ? null : () => _showGradeDialog(item),
          ),
        );
      },
    );
  }

  Widget _buildGradeSelector(String itemId) {
    final currentGrade = _currentGrades[itemId];

    return DropdownButton<String>(
      value: currentGrade,
      hint: const Text('Grade'),
      underline: const SizedBox(),
      items:
          Grade.allGrades.map((grade) {
            return DropdownMenuItem(
              value: grade.symbol,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: grade.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  grade.symbol,
                  style: TextStyle(
                    color: grade.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
      onChanged:
          _isFutureDate
              ? null
              : (value) {
                setState(() {
                  if (value != null) {
                    _currentGrades[itemId] = value;
                  } else {
                    _currentGrades.remove(itemId);
                  }
                  _hasUnsavedChanges = true;
                });
              },
    );
  }

  // Add card and swipe views similarly...
  Widget _buildCardView(HabitDataProvider habitData, Size screenSize) {
    return PageView.builder(
      itemCount: habitData.categories.length,
      itemBuilder: (context, index) {
        final category = habitData.categories[index];
        return Padding(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(screenSize.width * 0.06),
              child: Column(
                children: [
                  Icon(category.icon, size: 48, color: category.color),
                  SizedBox(height: screenSize.height * 0.02),
                  Text(
                    category.nameAr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(category.nameEn),
                  SizedBox(height: screenSize.height * 0.03),
                  Expanded(
                    child: ListView.builder(
                      itemCount: category.items.length,
                      itemBuilder: (context, itemIndex) {
                        final item = category.items[itemIndex];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.005,
                          ),
                          child: _buildHabitItemCard(item, screenSize),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeView(HabitDataProvider habitData, Size screenSize) {
    final allItems = habitData.categories.expand((cat) => cat.items).toList();

    return PageView.builder(
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        final category = habitData.categories.firstWhere(
          (cat) => cat.id == item.categoryId,
        );

        return Padding(
          padding: EdgeInsets.all(screenSize.width * 0.08),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(screenSize.width * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category.icon, size: 64, color: category.color),
                  SizedBox(height: screenSize.height * 0.03),
                  Text(
                    item.nameAr,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenSize.height * 0.01),
                  Text(
                    item.nameEn,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenSize.height * 0.04),
                  Text(
                    'Select Grade',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  Wrap(
                    spacing: screenSize.width * 0.02,
                    runSpacing: screenSize.height * 0.01,
                    children:
                        Grade.allGrades.map((grade) {
                          final isSelected =
                              _currentGrades[item.id] == grade.symbol;
                          return FilterChip(
                            label: Text(grade.symbol),
                            selected: isSelected,
                            onSelected:
                                _isFutureDate
                                    ? null
                                    : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _currentGrades[item.id] =
                                              grade.symbol;
                                        } else {
                                          _currentGrades.remove(item.id);
                                        }
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                            backgroundColor: grade.color.withOpacity(0.1),
                            selectedColor: grade.color.withOpacity(0.3),
                          );
                        }).toList(),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Text(
                    '${index + 1} of ${allItems.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
