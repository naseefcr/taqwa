// services/firestore_sync_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

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

  // Sync custom categories and items
  Future<void> syncCustomCategories(List<HabitCategory> categories) async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final userCategoriesRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories');

      for (final category in categories) {
        // Only sync custom items
        final customItems =
            category.items.where((item) => item.isCustom).toList();

        if (customItems.isNotEmpty) {
          final docRef = userCategoriesRef.doc(category.id);
          batch.set(docRef, {
            'categoryId': category.id,
            'customItems':
                customItems
                    .map(
                      (item) => {
                        'id': item.id,
                        'nameAr': item.nameAr,
                        'nameEn': item.nameEn,
                        'categoryId': item.categoryId,
                        'isCustom': item.isCustom,
                      },
                    )
                    .toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing custom categories: $e');
      }
      rethrow;
    }
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

  // Fetch custom categories
  Future<Map<String, List<HabitItem>>> fetchCustomCategories() async {
    if (_currentUserId == null) return {};

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('categories')
              .get();

      final customCategories = <String, List<HabitItem>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final categoryId = data['categoryId'] as String;
        final customItemsData = data['customItems'] as List<dynamic>? ?? [];

        final customItems =
            customItemsData.map((itemData) {
              return HabitItem(
                id: itemData['id'],
                nameAr: itemData['nameAr'],
                nameEn: itemData['nameEn'],
                categoryId: itemData['categoryId'],
                isCustom: itemData['isCustom'] ?? true,
              );
            }).toList();

        customCategories[categoryId] = customItems;
      }

      return customCategories;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching custom categories: $e');
      }
      return {};
    }
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
        fetchCustomCategories(),
        fetchUserSettings(),
      ]);

      _lastSyncTime = DateTime.now();

      return {
        'entries': results[0] as List<DailyEntry>,
        'customCategories': results[1] as Map<String, List<HabitItem>>,
        'settings': results[2] as Map<String, dynamic>,
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
      final collections = ['entries', 'categories', 'settings', 'profile'];

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
