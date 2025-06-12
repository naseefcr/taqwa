import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:taqwa/providers/habit_data_provider.dart';
import 'package:taqwa/providers/theme_provider.dart';
import 'package:taqwa/screens/analytics_screen.dart';
import 'package:taqwa/screens/settings_screen.dart';
import 'package:taqwa/screens/weekly_screen.dart';

import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  runApp(const TaqwaApp());
}

class TaqwaApp extends StatelessWidget {
  const TaqwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HabitDataProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Taqwa - Islamic Habit Tracker',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// Splash Screen with initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final habitProvider = Provider.of<HabitDataProvider>(
        context,
        listen: false,
      );

      // Initialize Hive and load data
      await habitProvider.initializeHive();

      // If no data exists, initialize with default data
      if (habitProvider.entries.isEmpty && habitProvider.categories.isEmpty) {
        habitProvider.initializeDefaultData();
      }

      // Navigate to main screen after initialization
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      print('Initialization error: $e');
      // Show error and navigate anyway
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mosque, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'تقوى',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Taqwa - Build God-Consciousness',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Screen with Bottom Navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const TodayScreen(),
    const WeeklyScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Weekly',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Today Screen - Main Daily Entry Screen
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final DateTime _selectedDate = DateTime.now();
  final Map<String, String> _todayGrades = {};

  @override
  void initState() {
    super.initState();
    _loadTodayEntry();
  }

  void _loadTodayEntry() {
    final habitData = Provider.of<HabitDataProvider>(context, listen: false);
    final todayEntry = habitData.getTodayEntry();
    if (todayEntry != null && todayEntry.itemGrades.isNotEmpty) {
      setState(() {
        _todayGrades.addAll(todayEntry.itemGrades);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitData = Provider.of<HabitDataProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final hijriDate = HijriCalendar.fromDate(_selectedDate);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
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
        actions: [
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
          // Daily Progress Card
          Container(
            margin: EdgeInsets.all(
              screenSize.width * 0.04,
            ), // Responsive margin
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(
                  screenSize.width * 0.04,
                ), // Responsive padding
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: screenSize.height * 0.01),
                          LinearProgressIndicator(
                            value:
                                habitData.calculateDayPercentage(_todayGrades) /
                                100,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: screenSize.width * 0.04),
                    Column(
                      children: [
                        Text(
                          '${habitData.calculateDayPercentage(_todayGrades).toStringAsFixed(1)}%',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${_todayGrades.length}/${_getTotalItems(habitData)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Entry Method Views
          Expanded(child: _buildEntryView(habitData, screenSize)),
        ],
      ),
      floatingActionButton:
          _todayGrades.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () {
                  habitData.saveDayEntry(_selectedDate, _todayGrades);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Day saved successfully!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Day'),
              )
              : null,
    );
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

  Widget _buildGridView(HabitDataProvider habitData, Size screenSize) {
    // Calculate responsive values
    final horizontalPadding = screenSize.width * 0.04; // 4% of screen width
    final verticalPadding = screenSize.height * 0.02; // 2% of screen height
    final cardMargin = screenSize.height * 0.02;
    final cardPadding = screenSize.width * 0.04;

    // Dynamic cross axis count based on screen width
    int crossAxisCount =
        screenSize.width > 600 ? 3 : 2; // 3 columns for tablets, 2 for phones

    // Dynamic aspect ratio based on screen size
    double childAspectRatio =
        screenSize.width > 600 ? 2.5 : 2.2; // Wider cards for larger screens

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
                    if (screenSize.width >
                        350) // Only show English name on larger screens
                      Text(' • ${category.nameEn}'),
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
          ),
        );
      },
    );
  }

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
                              _todayGrades[item.id] == grade.symbol;
                          return FilterChip(
                            label: Text(grade.symbol),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _todayGrades[item.id] = grade.symbol;
                                } else {
                                  _todayGrades.remove(item.id);
                                }
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

  Widget _buildHabitItemCard(HabitItem item, Size screenSize) {
    final currentGrade = _todayGrades[item.id];

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
        onTap: () => _showGradeDialog(item),
        borderRadius: BorderRadius.circular(12),
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
                    fontSize:
                        screenSize.width < 400
                            ? 12
                            : 14, // Responsive font size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Allow 2 lines for longer text
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: screenSize.height * 0.005),
              Flexible(
                child: Text(
                  item.nameEn,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize:
                        screenSize.width < 400
                            ? 10
                            : 12, // Responsive font size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Allow 2 lines for longer text
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
    );
  }

  Widget _buildGradeSelector(String itemId) {
    final currentGrade = _todayGrades[itemId];

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
      onChanged: (value) {
        setState(() {
          if (value != null) {
            _todayGrades[itemId] = value;
          } else {
            _todayGrades.remove(itemId);
          }
        });
      },
    );
  }

  void _showGradeDialog(HabitItem item) {
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
                      selected: _todayGrades[item.id] == grade.symbol,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _todayGrades[item.id] = grade.symbol;
                          } else {
                            _todayGrades.remove(item.id);
                          }
                        });
                        Navigator.pop(context);
                      },
                      backgroundColor: grade.color.withOpacity(0.1),
                      selectedColor: grade.color.withOpacity(0.3),
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
