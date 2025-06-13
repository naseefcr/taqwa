// providers/habit_data_provider.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import '../services/firestore_sync_service.dart';

class HabitDataProvider extends ChangeNotifier {
  // CRITICAL FIX: Initialize with default data immediately
  HabitDataProvider() {
    // Initialize default categories immediately to prevent empty state
    initializeDefaultData();
  }
  List<HabitCategory> _categories = [];
  List<DailyEntry> _entries = [];
  String _currentEntryMethod = 'grid'; // 'grid', 'list', 'card', 'swipe'

  // Firebase sync service
  FirestoreSyncService? _syncService;
  bool _isOnline = false;
  String? _lastSyncError;

  // Hive boxes
  Box<Map>? _entriesBox;
  Box<String>? _settingsBox;

  List<HabitCategory> get categories => _categories;
  List<DailyEntry> get entries => _entries;
  String get currentEntryMethod => _currentEntryMethod;
  bool get isOnline => _isOnline;
  String? get lastSyncError => _lastSyncError;
  bool get isSyncing => _syncService?.isSyncing ?? false;
  DateTime? get lastSyncTime => _syncService?.lastSyncTime;

  // Set the sync service (called from main.dart)
  void setSyncService(FirestoreSyncService syncService) {
    _syncService = syncService;
    _checkConnectivity();
  }

  // Check connectivity status
  Future<void> _checkConnectivity() async {
    if (_syncService != null) {
      try {
        _isOnline = await _syncService!.hasInternetConnection();
        notifyListeners();
      } catch (e) {
        _isOnline = false;
      }
    }
  }

  // Initialize Hive and load data
  Future<void> initializeHive() async {
    try {
      _entriesBox = await Hive.openBox<Map>('entries');
      _settingsBox = await Hive.openBox<String>('settings');

      await _loadDataFromHive();
      await _loadSettingsFromHive();
    } catch (e) {
      print('Error initializing Hive: $e');
      // Continue with default data if Hive fails
      initializeDefaultData();
    }
  }

  Future<void> _loadDataFromHive() async {
    if (_entriesBox == null) return;

    _entries.clear();

    for (var key in _entriesBox!.keys) {
      try {
        final entryMap = _entriesBox!.get(key);
        if (entryMap != null) {
          final entry = DailyEntry(
            date: DateTime.parse(entryMap['date']),
            itemGrades: Map<String, String>.from(entryMap['itemGrades']),
            percentage: entryMap['percentage']?.toDouble() ?? 0.0,
          );
          _entries.add(entry);
        }
      } catch (e) {
        print('Error loading entry $key: $e');
      }
    }

    _entries.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _loadSettingsFromHive() async {
    if (_settingsBox == null) return;

    _currentEntryMethod =
        _settingsBox!.get('entryMethod', defaultValue: 'grid')!;
  }

  Future<void> _saveEntryToHive(DailyEntry entry) async {
    if (_entriesBox == null) return;

    try {
      final key = entry.date.toIso8601String().split('T')[0];
      await _entriesBox!.put(key, {
        'date': entry.date.toIso8601String(),
        'itemGrades': entry.itemGrades,
        'percentage': entry.percentage,
      });
    } catch (e) {
      print('Error saving entry to Hive: $e');
    }
  }

  Future<void> _saveSettingsToHive() async {
    if (_settingsBox == null) return;

    try {
      await _settingsBox!.put('entryMethod', _currentEntryMethod);
    } catch (e) {
      print('Error saving settings to Hive: $e');
    }
  }

  // Sync with Firestore
  Future<void> syncWithFirestore() async {
    if (_syncService == null) return;

    try {
      _lastSyncError = null;
      await _checkConnectivity();

      if (!_isOnline) {
        _lastSyncError = 'No internet connection';
        notifyListeners();
        return;
      }

      // Perform full sync from Firestore
      final syncData = await _syncService!.performFullSync();

      // Update local data with synced data
      if (syncData.isNotEmpty) {
        // Merge entries
        final syncedEntries = syncData['entries'] as List<DailyEntry>? ?? [];
        _mergeEntries(syncedEntries);

        // Merge custom categories
        final customCategories =
            syncData['customCategories'] as Map<String, List<HabitItem>>? ?? {};
        _mergeCustomCategories(customCategories);

        // Update settings
        final settings = syncData['settings'] as Map<String, dynamic>? ?? {};
        if (settings.isNotEmpty) {
          _currentEntryMethod = settings['entryMethod'] ?? _currentEntryMethod;
          await _saveSettingsToHive();
        }

        // Save merged data to Hive
        for (final entry in _entries) {
          await _saveEntryToHive(entry);
        }

        notifyListeners();
      }

      // Sync local changes to Firestore
      await _syncLocalDataToFirestore();
    } catch (e) {
      _lastSyncError = e.toString();
      print('Sync error: $e');
      notifyListeners();
    }
  }

  void _mergeEntries(List<DailyEntry> syncedEntries) {
    final entriesMap = <String, DailyEntry>{};

    // Add existing entries to map
    for (final entry in _entries) {
      final key = entry.date.toIso8601String().split('T')[0];
      entriesMap[key] = entry;
    }

    // Merge synced entries (synced data takes precedence for conflicts)
    for (final entry in syncedEntries) {
      final key = entry.date.toIso8601String().split('T')[0];
      entriesMap[key] = entry;
    }

    _entries =
        entriesMap.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  void _mergeCustomCategories(Map<String, List<HabitItem>> customCategories) {
    for (final categoryEntry in customCategories.entries) {
      final categoryId = categoryEntry.key;
      final customItems = categoryEntry.value;

      final categoryIndex = _categories.indexWhere(
        (cat) => cat.id == categoryId,
      );
      if (categoryIndex != -1) {
        // Remove existing custom items for this category
        _categories[categoryIndex].items.removeWhere((item) => item.isCustom);

        // Add synced custom items
        _categories[categoryIndex].items.addAll(customItems);
      }
    }
  }

  Future<void> _syncLocalDataToFirestore() async {
    if (_syncService == null || !_isOnline) return;

    try {
      // Sync entries
      await _syncService!.syncDailyEntries(_entries);

      // Sync custom categories
      await _syncService!.syncCustomCategories(_categories);

      // Sync settings
      await _syncService!.syncUserSettings({
        'entryMethod': _currentEntryMethod,
      });
    } catch (e) {
      print('Error syncing local data to Firestore: $e');
      _lastSyncError = 'Failed to sync to cloud: $e';
      notifyListeners();
    }
  }

  void initializeDefaultData() {
    _categories = [
      HabitCategory(
        id: 'amal',
        nameAr: 'أعمال',
        nameEn: 'Worship',
        icon: Icons.mosque,
        color: Colors.green,
        items: [
          HabitItem(
            id: 'maghrib',
            nameAr: 'مغرب',
            nameEn: 'Maghrib',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'isha',
            nameAr: 'عشاء',
            nameEn: 'Isha',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'tahajjud',
            nameAr: 'تهجد',
            nameEn: 'Tahajjud',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'fajr',
            nameAr: 'فجر',
            nameEn: 'Fajr',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'ishraq',
            nameAr: 'إشراق',
            nameEn: 'Ishraq',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'dhuhr',
            nameAr: 'ظهر',
            nameEn: 'Dhuhr',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'asr',
            nameAr: 'عصر',
            nameEn: 'Asr',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'evening_dhikr',
            nameAr: 'أذكار المساء',
            nameEn: 'Evening Dhikr',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'morning_dhikr',
            nameAr: 'أذكار أصبح',
            nameEn: 'Morning Dhikr',
            categoryId: 'amal',
          ),
          HabitItem(
            id: 'sunnah_12',
            nameAr: '١٢ ركعة رواتب',
            nameEn: '12 Sunnah Rakahs',
            categoryId: 'amal',
          ),
        ],
      ),
      HabitCategory(
        id: 'quran',
        nameAr: 'قرآن',
        nameEn: 'Quran',
        icon: Icons.menu_book,
        color: Colors.blue,
        items: [
          HabitItem(
            id: 'four_surahs',
            nameAr: '٤ سوره',
            nameEn: '4 Surahs',
            categoryId: 'quran',
          ),
          HabitItem(
            id: 'amkhta',
            nameAr: 'امختہ',
            nameEn: 'Amkhta',
            categoryId: 'quran',
          ),
          HabitItem(
            id: 'mushaf',
            nameAr: 'مصحف',
            nameEn: 'Mushaf',
            categoryId: 'quran',
          ),
        ],
      ),
      HabitCategory(
        id: 'career',
        nameAr: 'مهنة',
        nameEn: 'Career',
        icon: Icons.work,
        color: Colors.purple,
        items: [
          HabitItem(
            id: 'tym',
            nameAr: 'TYM',
            nameEn: 'TYM',
            categoryId: 'career',
          ),
        ],
      ),
      HabitCategory(
        id: 'study',
        nameAr: 'دراسة',
        nameEn: 'Study',
        icon: Icons.school,
        color: Colors.orange,
        items: [
          HabitItem(
            id: 'seerah',
            nameAr: 'سيرة',
            nameEn: 'Seerah',
            categoryId: 'study',
          ),
        ],
      ),
      HabitCategory(
        id: 'home',
        nameAr: 'البيت',
        nameEn: 'Home',
        icon: Icons.home,
        color: Colors.teal,
        items: [
          HabitItem(
            id: 'dress',
            nameAr: 'لباس',
            nameEn: 'Dress',
            categoryId: 'home',
          ),
          HabitItem(
            id: 'agriculture',
            nameAr: 'زراعة',
            nameEn: 'Agriculture',
            categoryId: 'home',
          ),
          HabitItem(
            id: 'newspaper',
            nameAr: 'جريدة',
            nameEn: 'Newspaper',
            categoryId: 'home',
          ),
          HabitItem(
            id: 'clean',
            nameAr: 'تنظيف',
            nameEn: 'Clean',
            categoryId: 'home',
          ),
        ],
      ),
      HabitCategory(
        id: 'avoid',
        nameAr: 'تجنب غير المرغوب',
        nameEn: 'Avoid Unwanted',
        icon: Icons.block,
        color: Colors.red,
        items: [
          HabitItem(
            id: 'food_control',
            nameAr: 'طعام',
            nameEn: 'Food Control',
            categoryId: 'avoid',
          ),
          HabitItem(
            id: 'sleep_control',
            nameAr: 'نوم',
            nameEn: 'Sleep Control',
            categoryId: 'avoid',
          ),
          HabitItem(
            id: 'phone_control',
            nameAr: 'هاتف',
            nameEn: 'Phone Control',
            categoryId: 'avoid',
          ),
          HabitItem(
            id: 'talk_control',
            nameAr: 'كلام',
            nameEn: 'Talk Control',
            categoryId: 'avoid',
          ),
          HabitItem(
            id: 'p_control',
            nameAr: 'P',
            nameEn: 'P Control',
            categoryId: 'avoid',
          ),
        ],
      ),
      HabitCategory(
        id: 'dawah',
        nameAr: 'دعوة',
        nameEn: 'Dawah',
        icon: Icons.campaign,
        color: Colors.indigo,
        items: [
          HabitItem(
            id: 'fill_ontime',
            nameAr: 'Fill Ontime',
            nameEn: 'Fill Ontime',
            categoryId: 'dawah',
          ),
          HabitItem(
            id: 'heart_clean',
            nameAr: 'Heart clean before sleep',
            nameEn: 'Heart Clean Before Sleep',
            categoryId: 'dawah',
          ),
          HabitItem(
            id: 'class_fikr',
            nameAr: 'Class/ Fikr Paloth H/Mahal',
            nameEn: 'Class/Fikr',
            categoryId: 'dawah',
          ),
        ],
      ),
    ];
    notifyListeners();
  }

  void setEntryMethod(String method) {
    _currentEntryMethod = method;
    _saveSettingsToHive();

    // Sync settings to Firestore
    _syncSettingsToFirestore();

    notifyListeners();
  }

  Future<void> _syncSettingsToFirestore() async {
    if (_syncService != null && _isOnline) {
      try {
        await _syncService!.syncUserSettings({
          'entryMethod': _currentEntryMethod,
        });
      } catch (e) {
        print('Error syncing settings: $e');
      }
    }
  }

  void addCustomItem(String categoryId, String nameAr, String nameEn) {
    final categoryIndex = _categories.indexWhere((cat) => cat.id == categoryId);
    if (categoryIndex != -1) {
      final newItem = HabitItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nameAr: nameAr,
        nameEn: nameEn,
        categoryId: categoryId,
        isCustom: true,
      );
      _categories[categoryIndex].items.add(newItem);

      // Sync to Firestore
      _syncCustomCategoriesToFirestore();

      notifyListeners();
    }
  }

  void removeCustomItem(String itemId) {
    for (var category in _categories) {
      category.items.removeWhere((item) => item.id == itemId && item.isCustom);
    }

    // Sync to Firestore
    _syncCustomCategoriesToFirestore();

    notifyListeners();
  }

  Future<void> _syncCustomCategoriesToFirestore() async {
    if (_syncService != null && _isOnline) {
      try {
        await _syncService!.syncCustomCategories(_categories);
      } catch (e) {
        print('Error syncing custom categories: $e');
      }
    }
  }

  double calculateDayPercentage(Map<String, String> itemGrades) {
    if (itemGrades.isEmpty) return 0.0;

    int totalValue = 0;
    int totalItems = 0;

    for (var category in _categories) {
      for (var item in category.items) {
        final gradeSymbol = itemGrades[item.id];
        if (gradeSymbol != null) {
          final grade = Grade.allGrades.firstWhere(
            (g) => g.symbol == gradeSymbol,
            orElse: () => Grade.allGrades.last,
          );
          totalValue += grade.value;
          totalItems++;
        }
      }
    }

    return totalItems > 0 ? (totalValue / (totalItems * 10)) * 100 : 0.0;
  }

  Future<void> saveDayEntry(
    DateTime date,
    Map<String, String> itemGrades,
  ) async {
    final percentage = calculateDayPercentage(itemGrades);
    final entry = DailyEntry(
      date: date,
      itemGrades: itemGrades,
      percentage: percentage,
    );

    _entries.removeWhere((e) => isSameDay(e.date, date));
    _entries.add(entry);
    _entries.sort((a, b) => b.date.compareTo(a.date));

    // Save to Hive
    await _saveEntryToHive(entry);

    // Sync to Firestore
    if (_syncService != null) {
      try {
        await _checkConnectivity();
        if (_isOnline) {
          await _syncService!.syncSingleEntry(entry);
          _lastSyncError = null;
        } else {
          _lastSyncError = 'Entry saved locally. Will sync when online.';
        }
      } catch (e) {
        _lastSyncError = 'Sync error: $e';
        print('Error syncing entry: $e');
      }
    }

    notifyListeners();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DailyEntry> getWeekEntries(DateTime weekStart) {
    return _entries.where((entry) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      return entry.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          entry.date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, double> getWeeklyAverages(DateTime weekStart) {
    final weekEntries = getWeekEntries(weekStart);
    Map<String, List<int>> itemValues = {};

    for (var category in _categories) {
      for (var item in category.items) {
        itemValues[item.id] = [];
      }
    }

    for (var entry in weekEntries) {
      for (var itemId in entry.itemGrades.keys) {
        final gradeSymbol = entry.itemGrades[itemId]!;
        final grade = Grade.allGrades.firstWhere(
          (g) => g.symbol == gradeSymbol,
          orElse: () => Grade.allGrades.last,
        );
        itemValues[itemId]?.add(grade.value);
      }
    }

    Map<String, double> averages = {};
    for (var itemId in itemValues.keys) {
      final values = itemValues[itemId]!;
      if (values.isNotEmpty) {
        averages[itemId] = values.reduce((a, b) => a + b) / values.length;
      } else {
        averages[itemId] = 0.0;
      }
    }

    return averages;
  }

  // Reset all data
  Future<void> resetAllData() async {
    _entries.clear();

    // Clear Hive data
    if (_entriesBox != null) {
      await _entriesBox!.clear();
    }

    // Clear Firestore data if authenticated
    if (_syncService != null && _isOnline) {
      try {
        await _syncService!.deleteUserData();
      } catch (e) {
        print('Error clearing Firestore data: $e');
      }
    }

    notifyListeners();
  }

  // Generate sample data for testing
  void generateSampleData() {
    final now = DateTime.now();
    final random = [8, 9, 7, 10, 6, 8, 9, 7, 8, 10, 9, 8, 7, 9, 8];

    for (int i = 0; i < 15; i++) {
      final date = now.subtract(Duration(days: i));
      final itemGrades = <String, String>{};

      // Add some random grades for sample data
      for (var category in _categories) {
        for (var item in category.items) {
          if (i % 3 != 0 || item.id == 'fajr') {
            final gradeValue = random[i % random.length];
            final grade = Grade.allGrades.firstWhere(
              (g) => g.value == gradeValue,
              orElse: () => Grade.allGrades.first,
            );
            itemGrades[item.id] = grade.symbol;
          }
        }
      }

      if (itemGrades.isNotEmpty) {
        saveDayEntry(date, itemGrades);
      }
    }
  }

  // Export data as JSON
  Map<String, dynamic> exportData() {
    return {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'entries':
          _entries
              .map(
                (entry) => {
                  'date': entry.date.toIso8601String(),
                  'itemGrades': entry.itemGrades,
                  'percentage': entry.percentage,
                },
              )
              .toList(),
      'customItems': _getCustomItems(),
      'settings': {'entryMethod': _currentEntryMethod},
      'syncInfo': {
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'isOnline': _isOnline,
        'lastSyncError': _lastSyncError,
      },
    };
  }

  List<Map<String, dynamic>> _getCustomItems() {
    final customItems = <Map<String, dynamic>>[];

    for (var category in _categories) {
      for (var item in category.items) {
        if (item.isCustom) {
          customItems.add({
            'id': item.id,
            'nameAr': item.nameAr,
            'nameEn': item.nameEn,
            'categoryId': item.categoryId,
          });
        }
      }
    }

    return customItems;
  }

  // Import data from JSON
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      await resetAllData();

      // Import entries
      if (data['entries'] != null) {
        for (var entryData in data['entries']) {
          final entry = DailyEntry(
            date: DateTime.parse(entryData['date']),
            itemGrades: Map<String, String>.from(entryData['itemGrades']),
            percentage: entryData['percentage']?.toDouble() ?? 0.0,
          );
          _entries.add(entry);
          await _saveEntryToHive(entry);
        }
      }

      // Import custom items
      if (data['customItems'] != null) {
        for (var itemData in data['customItems']) {
          addCustomItem(
            itemData['categoryId'],
            itemData['nameAr'],
            itemData['nameEn'],
          );
        }
      }

      // Import settings
      if (data['settings'] != null) {
        _currentEntryMethod = data['settings']['entryMethod'] ?? 'grid';
        await _saveSettingsToHive();
      }

      _entries.sort((a, b) => b.date.compareTo(a.date));

      // Sync imported data to Firestore
      await _syncLocalDataToFirestore();

      notifyListeners();
    } catch (e) {
      print('Error importing data: $e');
      throw Exception('Failed to import data');
    }
  }

  // Get today's entry if exists
  DailyEntry? getTodayEntry() {
    final today = DateTime.now();
    try {
      return _entries.firstWhere((entry) => isSameDay(entry.date, today));
    } catch (e) {
      return null;
    }
  }

  // Check if user has entry for today
  bool hasTodayEntry() {
    final today = DateTime.now();
    return _entries.any((entry) => isSameDay(entry.date, today));
  }

  // Get streak information
  Map<String, int> getStreakInfo() {
    if (_entries.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    final sortedEntries =
        _entries.toList()..sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (var entry in sortedEntries) {
      if (entry.percentage >= 70) {
        if (lastDate == null || entry.date.difference(lastDate).inDays == 1) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }

        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

        if (isSameDay(entry.date, DateTime.now()) ||
            entry.date.difference(DateTime.now()).inDays == -1) {
          currentStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }

      lastDate = entry.date;
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  // Force sync with Firestore
  Future<void> forceSyncWithFirestore() async {
    try {
      await syncWithFirestore();
    } catch (e) {
      _lastSyncError = 'Force sync failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Get sync status for UI
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'isSyncing': isSyncing,
      'lastSyncTime': lastSyncTime,
      'lastSyncError': _lastSyncError,
    };
  }
}
