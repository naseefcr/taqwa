// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/habit_data_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/auth_screens.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final habitData = Provider.of<HabitDataProvider>(context);
    final authService = Provider.of<FirebaseAuthService>(context);
    final syncService = Provider.of<FirestoreSyncService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          // Sync status indicator
          if (syncService.isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildAccountCard(authService, habitData),

          const SizedBox(height: 24),

          // Sync Section
          _buildSectionHeader('Data Sync'),
          _buildSyncStatusCard(syncService, habitData),
          _buildSyncControls(syncService, habitData),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          _buildThemeToggle(themeProvider),
          _buildLanguageSelector(),
          _buildNotificationSettings(),

          const SizedBox(height: 24),

          // Habit Management Section
          _buildSectionHeader('Habit Management'),
          _buildManageCategories(habitData),
          _buildDefaultEntryMethod(habitData),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data Management'),
          _buildDataExport(habitData),
          _buildDataImport(habitData),
          _buildResetOptions(habitData, authService),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildAboutApp(),
          _buildVersionInfo(),

          const SizedBox(height: 24),

          // Advanced Section
          _buildSectionHeader('Advanced'),
          _buildDeveloperOptions(habitData),

          // Account deletion (if authenticated)
          if (authService.isAuthenticated) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Danger Zone'),
            _buildDeleteAccountOption(authService, habitData),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    FirebaseAuthService authService,
    HabitDataProvider habitData,
  ) {
    final user = authService.currentUser;
    final syncStatus = habitData.getSyncStatus();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage:
                      user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                  child:
                      user?.photoURL == null
                          ? Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user?.email ?? 'No email',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            syncStatus['isOnline']
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            size: 16,
                            color:
                                syncStatus['isOnline']
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            syncStatus['isOnline'] ? 'Online' : 'Offline',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  syncStatus['isOnline']
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showSignOutDialog(authService),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
            if (!authService.isEmailVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email not verified. Verify to secure your account.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _sendEmailVerification(authService),
                      child: const Text('Verify'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(
    FirestoreSyncService syncService,
    HabitDataProvider habitData,
  ) {
    final syncStatus = habitData.getSyncStatus();
    final lastSyncTime = syncStatus['lastSyncTime'] as DateTime?;
    final lastSyncError = syncStatus['lastSyncError'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  syncStatus['isOnline'] ? Icons.sync : Icons.sync_problem,
                  color: syncStatus['isOnline'] ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sync Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (syncStatus['isSyncing'])
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (lastSyncTime != null) ...[
              Text(
                'Last synced: ${DateFormat('MMM d, yyyy at h:mm a').format(lastSyncTime)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              Text(
                'Never synced',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange),
              ),
            ],
            if (lastSyncError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastSyncError,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncControls(
    FirestoreSyncService syncService,
    HabitDataProvider habitData,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.sync,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Sync Now'),
            subtitle: const Text('Manually sync your data with the cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _performManualSync(habitData),
          ),
          ListTile(
            leading: Icon(
              Icons.cloud_download,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Restore from Cloud'),
            subtitle: const Text('Download and restore data from cloud backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRestoreFromCloudDialog(habitData),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Switch between light and dark themes'),
        secondary: Icon(
          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: Theme.of(context).colorScheme.primary,
        ),
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.language,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Language'),
        subtitle: const Text('English (العربية coming soon)'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showLanguageDialog();
        },
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.notifications,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Notifications'),
        subtitle: const Text('Daily reminders and motivational messages'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showNotificationSettings();
        },
      ),
    );
  }

  Widget _buildManageCategories(HabitDataProvider habitData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.category,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Manage Categories'),
        subtitle: const Text('Add, edit, or remove habit categories'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showManageCategoriesDialog(habitData);
        },
      ),
    );
  }

  Widget _buildDefaultEntryMethod(HabitDataProvider habitData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.view_module,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Default Entry Method'),
        subtitle: Text(
          'Current: ${_getEntryMethodName(habitData.currentEntryMethod)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showEntryMethodDialog(habitData);
        },
      ),
    );
  }

  Widget _buildDataExport(HabitDataProvider habitData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.file_download,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Export Data'),
        subtitle: const Text('Download your data as JSON file'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _exportData(habitData);
        },
      ),
    );
  }

  Widget _buildDataImport(HabitDataProvider habitData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.file_upload,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Import Data'),
        subtitle: const Text('Restore data from backup file'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _importData(habitData);
        },
      ),
    );
  }

  Widget _buildResetOptions(
    HabitDataProvider habitData,
    FirebaseAuthService authService,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.refresh, color: Colors.orange),
        title: const Text('Reset Data'),
        subtitle: Text(
          authService.isAuthenticated
              ? 'Clear all local and cloud data (cannot be undone)'
              : 'Clear all local data (cannot be undone)',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showResetConfirmationDialog(habitData, authService.isAuthenticated);
        },
      ),
    );
  }

  Widget _buildAboutApp() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
        title: const Text('About Taqwa'),
        subtitle: const Text('Learn more about this app'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showAboutDialog();
        },
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.update,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Version'),
        subtitle: const Text('1.0.0'),
        trailing: TextButton(
          onPressed: () {
            _checkForUpdates();
          },
          child: const Text('Check Updates'),
        ),
      ),
    );
  }

  Widget _buildDeveloperOptions(HabitDataProvider habitData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.developer_mode,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Developer Options'),
        subtitle: const Text('Advanced settings and debugging'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showDeveloperOptions(habitData);
        },
      ),
    );
  }

  Widget _buildDeleteAccountOption(
    FirebaseAuthService authService,
    HabitDataProvider habitData,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text('Delete Account'),
        subtitle: const Text('Permanently delete your account and all data'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showDeleteAccountDialog(authService, habitData);
        },
      ),
    );
  }

  // Helper methods and dialog implementations

  String _getEntryMethodName(String method) {
    switch (method) {
      case 'grid':
        return 'Grid View';
      case 'list':
        return 'List View';
      case 'card':
        return 'Card View';
      case 'swipe':
        return 'Swipe View';
      default:
        return 'Grid View';
    }
  }

  Future<void> _performManualSync(HabitDataProvider habitData) async {
    try {
      await habitData.forceSyncWithFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sync completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSignOutDialog(FirebaseAuthService authService) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sign out failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  Future<void> _sendEmailVerification(FirebaseAuthService authService) async {
    try {
      await authService.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestoreFromCloudDialog(HabitDataProvider habitData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore from Cloud'),
            content: const Text(
              'This will replace all local data with your cloud backup. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await habitData.syncWithFirestore();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Data restored from cloud!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Restore failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('Restore'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(
    FirebaseAuthService authService,
    HabitDataProvider habitData,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'This will permanently delete your account and all associated data. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    // First clear all user data from Firestore
                    await habitData.resetAllData();

                    // Then delete the Firebase account
                    await authService.deleteAccount();

                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Account deletion failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete Forever'),
              ),
            ],
          ),
    );
  }

  void _showResetConfirmationDialog(
    HabitDataProvider habitData,
    bool isAuthenticated,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset All Data'),
            content: Text(
              isAuthenticated
                  ? 'Are you sure you want to delete all your tracking data from both local storage and cloud? This action cannot be undone.'
                  : 'Are you sure you want to delete all your local tracking data? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await habitData.resetAllData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All data has been reset'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reset failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }

  // Add the rest of your existing dialog methods here
  // (_showLanguageDialog, _showNotificationSettings, _showManageCategoriesDialog, etc.)
  // Copy them from your original settings_screen.dart

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: 'en',
                  onChanged: (value) {
                    Navigator.pop(context);
                    // TODO: Implement language change
                  },
                ),
                RadioListTile<String>(
                  title: const Text('العربية (Coming Soon)'),
                  value: 'ar',
                  groupValue: 'en',
                  onChanged: null,
                ),
              ],
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

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notification Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Daily Reminder'),
                  subtitle: const Text('Remind to fill daily tracker'),
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement notification toggle
                  },
                ),
                SwitchListTile(
                  title: const Text('Prayer Time Alerts'),
                  subtitle: const Text('Prayer time notifications'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement prayer time notifications
                  },
                ),
                SwitchListTile(
                  title: const Text('Motivational Messages'),
                  subtitle: const Text('Daily Islamic motivational quotes'),
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement motivational messages
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  void _showManageCategoriesDialog(HabitDataProvider habitData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Manage Categories'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: habitData.categories.length,
                itemBuilder: (context, index) {
                  final category = habitData.categories[index];
                  return Card(
                    child: ExpansionTile(
                      leading: Icon(category.icon, color: category.color),
                      title: Text(category.nameAr),
                      subtitle: Text('${category.items.length} items'),
                      children: [
                        ...category.items.map(
                          (item) => ListTile(
                            title: Text(item.nameAr),
                            subtitle: Text(item.nameEn),
                            trailing:
                                item.isCustom
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        habitData.removeCustomItem(item.id);
                                      },
                                    )
                                    : null,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Add Custom Item'),
                          onTap: () {
                            _showAddCustomItemDialog(habitData, category.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  void _showAddCustomItemDialog(
    HabitDataProvider habitData,
    String categoryId,
  ) {
    final arabicController = TextEditingController();
    final englishController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Custom Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: arabicController,
                  decoration: const InputDecoration(
                    labelText: 'Arabic Name',
                    hintText: 'اسم العادة بالعربية',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: englishController,
                  decoration: const InputDecoration(
                    labelText: 'English Name',
                    hintText: 'Habit name in English',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (arabicController.text.isNotEmpty &&
                      englishController.text.isNotEmpty) {
                    habitData.addCustomItem(
                      categoryId,
                      arabicController.text,
                      englishController.text,
                    );
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _showManageCategoriesDialog(habitData);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEntryMethodDialog(HabitDataProvider habitData) {
    final methods = ['grid', 'list', 'card', 'swipe'];
    final methodNames = ['Grid View', 'List View', 'Card View', 'Swipe View'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Default Entry Method'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  methods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final method = entry.value;
                    return RadioListTile<String>(
                      title: Text(methodNames[index]),
                      value: method,
                      groupValue: habitData.currentEntryMethod,
                      onChanged: (value) {
                        if (value != null) {
                          habitData.setEntryMethod(value);
                          Navigator.pop(context);
                        }
                      },
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

  void _exportData(HabitDataProvider habitData) {
    try {
      final data = habitData.exportData();
      // TODO: Implement actual file export
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data export feature coming soon!')),
      );
      print('Export data: $data'); // For debugging
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importData(HabitDataProvider habitData) {
    // TODO: Implement data import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data import feature coming soon!')),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Taqwa',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.mosque, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'Taqwa is an Islamic habit tracker designed to help Muslims build consistent spiritual practices and develop God-consciousness (Taqwa) in their daily lives.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• Track 27 daily spiritual and personal habits\n'
          '• Multiple entry methods for personalized experience\n'
          '• Weekly and monthly analytics\n'
          '• Achievement system for motivation\n'
          '• Cloud sync with Firebase\n'
          '• Beautiful Islamic-inspired design',
        ),
        const SizedBox(height: 16),
        const Text(
          'May Allah accept our efforts and make us among the Muttaqin (those who have Taqwa).',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You are using the latest version!')),
    );
  }

  void _showDeveloperOptions(HabitDataProvider habitData) {
    final syncStatus = habitData.getSyncStatus();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Developer Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Generate Sample Data'),
                  onTap: () {
                    habitData.generateSampleData();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample data generated')),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Force Sync'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _performManualSync(habitData);
                  },
                ),
                ListTile(
                  title: const Text('Debug Info'),
                  onTap: () {
                    final entries = habitData.entries;
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Debug Info'),
                            content: Text(
                              'Total Entries: ${entries.length}\n'
                              'Categories: ${habitData.categories.length}\n'
                              'Entry Method: ${habitData.currentEntryMethod}\n'
                              'Online: ${syncStatus['isOnline']}\n'
                              'Syncing: ${syncStatus['isSyncing']}\n'
                              'Last Sync: ${syncStatus['lastSyncTime']}\n'
                              'Sync Error: ${syncStatus['lastSyncError'] ?? 'None'}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
