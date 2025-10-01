// services/firestore_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class FirestoreSyncService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _currentUserId;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Initialize service with user ID
  void initialize(String userId) {
    _currentUserId = userId;
    _enableOfflineSupport();
  }

  // Enable offline support for Firestore
  void _enableOfflineSupport() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Firestore Collections Structure:
  // /users/{userId}/profile
  // /users/{userId}/entries/{dateString}
  // /users/{userId}/categories/{categoryId}
  // /users/{userId}/settings/userSettings

  // Sync user profile
  Future<void> syncUserProfile(Map<String, dynamic> profileData) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('profile')
          .doc('data')
          .set({
            ...profileData,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing user profile: $e');
      }
      rethrow;
    }
  }

  // Sync daily entries to Firestore
  Future<void> syncDailyEntries(List<DailyEntry> entries) async {
    if (_currentUserId == null || entries.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final userEntriesRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('entries');

      for (final entry in entries) {
        final dateString = entry.date.toIso8601String().split('T')[0];
        final docRef = userEntriesRef.doc(dateString);

        batch.set(docRef, {
          'date': Timestamp.fromDate(entry.date),
          'itemGrades': entry.itemGrades,
          'percentage': entry.percentage,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing daily entries: $e');
      }
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Sync single daily entry
  Future<void> syncSingleEntry(DailyEntry entry) async {
    if (_currentUserId == null) return;

    try {
      final dateString = entry.date.toIso8601String().split('T')[0];
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('entries')
          .doc(dateString)
          .set({
            'date': Timestamp.fromDate(entry.date),
            'itemGrades': entry.itemGrades,
            'percentage': entry.percentage,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing single entry: $e');
      }
      // Don't rethrow for single entry sync to avoid disrupting user experience
    }
  }

  // Sync all categories
  Future<void> syncCategories(List<HabitCategory> categories) async {
    if (_currentUserId == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final userCategoriesRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories');

      for (final category in categories) {
        final docRef = userCategoriesRef.doc(category.id);
        batch.set(docRef, category.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing categories: $e');
      }
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Add single category
  Future<void> addCategory(HabitCategory category) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .doc(category.id)
          .set(category.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error adding category: $e');
      }
      rethrow;
    }
  }

  // Update category
  Future<void> updateCategory(HabitCategory category) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .doc(category.id)
          .update(category.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating category: $e');
      }
      rethrow;
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .doc(categoryId)
          .delete();

      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('items')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      final batch = _firestore.batch();
      for (final doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting category: $e');
      }
      rethrow;
    }
  }

  // Sync all items
  Future<void> syncItems(List<HabitItem> items) async {
    if (_currentUserId == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final userItemsRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('items');

      for (final item in items) {
        final docRef = userItemsRef.doc(item.id);
        batch.set(docRef, item.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing items: $e');
      }
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Add single item
  Future<void> addItem(HabitItem item) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('items')
          .doc(item.id)
          .set(item.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error adding item: $e');
      }
      rethrow;
    }
  }

  // Update item
  Future<void> updateItem(HabitItem item) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('items')
          .doc(item.id)
          .update(item.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating item: $e');
      }
      rethrow;
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting item: $e');
      }
      rethrow;
    }
  }

  // Keep old method for backward compatibility
  Future<void> syncCustomCategories(List<HabitCategory> categories) async {
    await syncCategories(categories);
    
    final allItems = <HabitItem>[];
    for (final category in categories) {
      allItems.addAll(category.items);
    }
    await syncItems(allItems);
  }

  // Sync user settings
  Future<void> syncUserSettings(Map<String, dynamic> settings) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('userSettings')
          .set({
            ...settings,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing user settings: $e');
      }
      rethrow;
    }
  }

  // Fetch data from Firestore
  Future<List<DailyEntry>> fetchDailyEntries() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('entries')
              .orderBy('date', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DailyEntry(
          date: (data['date'] as Timestamp).toDate(),
          itemGrades: Map<String, String>.from(data['itemGrades'] ?? {}),
          percentage: (data['percentage'] ?? 0.0).toDouble(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching daily entries: $e');
      }
      return [];
    }
  }

  // Fetch all categories
  Future<List<HabitCategory>> fetchCategories() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        return HabitCategory.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching categories: $e');
      }
      return [];
    }
  }

  // Fetch all items
  Future<List<HabitItem>> fetchItems() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('items')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) {
        return HabitItem.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching items: $e');
      }
      return [];
    }
  }

  // Keep old method for backward compatibility
  Future<Map<String, List<HabitItem>>> fetchCustomCategories() async {
    final items = await fetchItems();
    final customCategories = <String, List<HabitItem>>{};

    for (final item in items) {
      if (item.isCustom) {
        if (!customCategories.containsKey(item.categoryId)) {
          customCategories[item.categoryId] = [];
        }
        customCategories[item.categoryId]!.add(item);
      }
    }

    return customCategories;
  }

  // Fetch user settings
  Future<Map<String, dynamic>> fetchUserSettings() async {
    if (_currentUserId == null) return {};

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('settings')
              .doc('userSettings')
              .get();

      return doc.data() ?? {};
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user settings: $e');
      }
      return {};
    }
  }

  // Full sync (download all data from Firestore)
  Future<Map<String, dynamic>> performFullSync() async {
    if (_currentUserId == null) return {};

    _isSyncing = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        fetchDailyEntries(),
        fetchCategories(),
        fetchItems(),
        fetchUserSettings(),
      ]);

      _lastSyncTime = DateTime.now();

      return {
        'entries': results[0] as List<DailyEntry>,
        'categories': results[1] as List<HabitCategory>,
        'items': results[2] as List<HabitItem>,
        'settings': results[3] as Map<String, dynamic>,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error performing full sync: $e');
      }
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Apply template to user's account
  Future<void> applyTemplate(Template template) async {
    if (_currentUserId == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      final categoriesRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories');

      final itemsRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('items');

      for (final categoryTemplate in template.categories) {
        final category = HabitCategory(
          id: categoryTemplate.id,
          nameAr: categoryTemplate.nameAr,
          nameEn: categoryTemplate.nameEn,
          icon: IconData(
            categoryTemplate.iconCodePoint,
            fontFamily: categoryTemplate.iconFontFamily,
          ),
          color: Color(categoryTemplate.colorValue),
          items: [],
          order: categoryTemplate.order,
          isCustom: false,
          isEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        batch.set(
          categoriesRef.doc(category.id),
          category.toFirestore(),
        );

        for (final itemTemplate in categoryTemplate.items) {
          final item = HabitItem(
            id: itemTemplate.id,
            nameAr: itemTemplate.nameAr,
            nameEn: itemTemplate.nameEn,
            categoryId: categoryTemplate.id,
            order: itemTemplate.order,
            isCustom: false,
            isEnabled: true,
            createdAt: now,
            updatedAt: now,
          );

          batch.set(
            itemsRef.doc(item.id),
            item.toFirestore(),
          );
        }
      }

      await batch.commit();

      await syncUserSettings({
        'selectedTemplate': template.id,
        'templateAppliedAt': now.toIso8601String(),
      });

      _lastSyncTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('Error applying template: $e');
      }
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Check if user has any categories
  Future<bool> userHasCategories() async {
    if (_currentUserId == null) return false;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user categories: $e');
      }
      return false;
    }
  }

  // Check connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Listen to real-time updates
  Stream<List<DailyEntry>> listenToEntriesUpdates() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('entries')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return DailyEntry(
              date: (data['date'] as Timestamp).toDate(),
              itemGrades: Map<String, String>.from(data['itemGrades'] ?? {}),
              percentage: (data['percentage'] ?? 0.0).toDouble(),
            );
          }).toList();
        });
  }

  // Delete user data
  Future<void> deleteUserData() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();

      // Delete all subcollections
      final collections = ['entries', 'categories', 'items', 'settings', 'profile'];

      for (final collection in collections) {
        final snapshot =
            await _firestore
                .collection('users')
                .doc(_currentUserId)
                .collection(collection)
                .get();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      // Delete user document
      batch.delete(_firestore.collection('users').doc(_currentUserId));

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user data: $e');
      }
      rethrow;
    }
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isSyncing': _isSyncing,
      'currentUserId': _currentUserId,
    };
  }

  // Clean up
  void dispose() {
    _currentUserId = null;
    _lastSyncTime = null;
    _isSyncing = false;
    super.dispose();
  }
}
