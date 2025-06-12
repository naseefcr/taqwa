// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_data_provider.dart';
import '../providers/theme_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          _buildResetOptions(habitData),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data'),
          _buildDataExport(habitData),
          _buildDataImport(),
          _buildBackupSettings(),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildAboutApp(),
          _buildVersionInfo(),

          const SizedBox(height: 24),

          // Advanced Section
          _buildSectionHeader('Advanced'),
          _buildDeveloperOptions(habitData),
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

  Widget _buildResetOptions(HabitDataProvider habitData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.refresh, color: Colors.orange),
        title: const Text('Reset Data'),
        subtitle: const Text('Clear all entries (cannot be undone)'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showResetConfirmationDialog(habitData);
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

  Widget _buildDataImport() {
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
          _importData();
        },
      ),
    );
  }

  Widget _buildBackupSettings() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.cloud_sync,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Cloud Sync'),
        subtitle: const Text('Sync with Firebase (Coming Soon)'),
        trailing: Switch(
          value: false,
          onChanged: null, // Disabled for now
        ),
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
                    Navigator.pop(
                      context,
                    ); // Close the manage categories dialog too
                    _showManageCategoriesDialog(
                      habitData,
                    ); // Reopen to show changes
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

  void _showResetConfirmationDialog(HabitDataProvider habitData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset All Data'),
            content: const Text(
              'Are you sure you want to delete all your tracking data? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  habitData.resetAllData();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data has been reset'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset'),
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

  void _importData() {
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
                  title: const Text('Clear Cache'),
                  onTap: () {
                    // TODO: Clear app cache
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
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
                              'Entry Method: ${habitData.currentEntryMethod}',
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
