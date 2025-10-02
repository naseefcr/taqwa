import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers/habit_data_provider.dart';
import '../data/templates.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories & Items'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'switch_template') {
                _showTemplateSwitcher(context);
              } else if (value == 'reset_current') {
                _showResetCurrentDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'switch_template',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz),
                    SizedBox(width: 8),
                    Text('Switch Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_current',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reset to Default'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Items', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoriesTab(),
          _ItemsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Category' : 'Add Item'),
      ),
    );
  }

  void _showAddDialog() {
    if (_tabController.index == 0) {
      _showAddCategoryDialog();
    } else {
      _showAddItemDialog();
    }
  }

  void _showAddCategoryDialog() {
    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    IconData selectedIcon = Icons.category;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                    labelText: 'Arabic Name',
                    hintText: 'اسم الفئة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'English Name',
                    hintText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Icon: '),
                    IconButton(
                      icon: Icon(selectedIcon, color: selectedColor),
                      onPressed: () {
                        _showIconPicker(context, (icon) {
                          setState(() {
                            selectedIcon = icon;
                          });
                        });
                      },
                    ),
                    const Spacer(),
                    const Text('Color: '),
                    GestureDetector(
                      onTap: () {
                        _showColorPicker(context, (color) {
                          setState(() {
                            selectedColor = color;
                          });
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameArController.text.isNotEmpty && nameEnController.text.isNotEmpty) {
                  final habitProvider = Provider.of<HabitDataProvider>(this.context, listen: false);
                  final now = DateTime.now();
                  final newCategory = HabitCategory(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nameAr: nameArController.text,
                    nameEn: nameEnController.text,
                    icon: selectedIcon,
                    color: selectedColor,
                    items: [],
                    order: habitProvider.categories.length,
                    isCustom: true,
                    isEnabled: true,
                    createdAt: now,
                    updatedAt: now,
                  );
                  habitProvider.addCategory(newCategory);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Category added successfully')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final habitProvider = Provider.of<HabitDataProvider>(context, listen: false);
    final categories = habitProvider.categories;

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a category first')),
      );
      return;
    }

    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    String? selectedCategoryId = categories.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.nameEn),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                    labelText: 'Arabic Name',
                    hintText: 'اسم العادة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'English Name',
                    hintText: 'Habit Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameArController.text.isNotEmpty && 
                    nameEnController.text.isNotEmpty && 
                    selectedCategoryId != null) {
                  final category = categories.firstWhere((c) => c.id == selectedCategoryId);
                  final now = DateTime.now();
                  final newItem = HabitItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nameAr: nameArController.text,
                    nameEn: nameEnController.text,
                    categoryId: selectedCategoryId!,
                    order: category.items.length,
                    isCustom: true,
                    isEnabled: true,
                    createdAt: now,
                    updatedAt: now,
                  );
                  habitProvider.addItem(selectedCategoryId!, newItem);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context, Function(IconData) onIconSelected) {
    final icons = [
      Icons.mosque,
      Icons.menu_book,
      Icons.favorite,
      Icons.star,
      Icons.work,
      Icons.school,
      Icons.home,
      Icons.restaurant,
      Icons.fitness_center,
      Icons.self_improvement,
      Icons.spa,
      Icons.night_shelter,
      Icons.campaign,
      Icons.volunteer_activism,
      Icons.family_restroom,
      Icons.psychology,
      Icons.block,
      Icons.access_time,
      Icons.calendar_today,
      Icons.local_hospital,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              return IconButton(
                icon: Icon(icons[index]),
                onPressed: () {
                  onIconSelected(icons[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, Function(Color) onColorSelected) {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  onColorSelected(colors[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTemplateSwitcher(BuildContext context) {
    final templates = HabitTemplates.getAllTemplates().where((t) => t.id != 'blank').toList();
    Template? selectedTemplate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Switch Template'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will replace all current categories and items. Your existing data will be lost.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSelected = selectedTemplate?.id == template.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(template.icon),
                          title: Text(template.nameEn),
                          subtitle: Text(
                            '${template.categories.length} categories • ${template.categories.fold<int>(0, (sum, cat) => sum + cat.items.length)} items',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              selectedTemplate = template;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedTemplate == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _applyTemplate(context, selectedTemplate!);
                    },
              child: const Text('Switch'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetCurrentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text(
          'This will reset all categories and items to the default Islamic template. Your current configuration will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final defaultTemplate = HabitTemplates.getTemplateById('default_islamic');
              await _applyTemplate(context, defaultTemplate);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyTemplate(BuildContext context, Template template) async {
    final habitProvider = Provider.of<HabitDataProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Applying template...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await habitProvider.applyTemplate(template);
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${template.nameEn}" applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitDataProvider>(context);
    final categories = habitProvider.categories;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = categories.removeAt(oldIndex);
        categories.insert(newIndex, item);
        
        for (int i = 0; i < categories.length; i++) {
          final updated = categories[i].copyWith(order: i, updatedAt: DateTime.now());
          habitProvider.updateCategory(updated);
        }
      },
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          key: ValueKey(category.id),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Icon(category.icon, color: category.color),
              ],
            ),
            title: Text(category.nameEn),
            subtitle: Text('${category.nameAr} • ${category.items.length} items'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category.isCustom)
                  Chip(
                    label: const Text('Custom'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(category.isEnabled ? Icons.visibility_off : Icons.visibility),
                          const SizedBox(width: 8),
                          Text(category.isEnabled ? 'Disable' : 'Enable'),
                        ],
                      ),
                    ),
                    if (category.isCustom)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCategoryDialog(context, category);
                        break;
                      case 'toggle':
                        final updated = category.copyWith(
                          isEnabled: !category.isEnabled,
                          updatedAt: DateTime.now(),
                        );
                        habitProvider.updateCategory(updated);
                        break;
                      case 'delete':
                        _showDeleteCategoryDialog(context, category);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, HabitCategory category) {
    final nameArController = TextEditingController(text: category.nameAr);
    final nameEnController = TextEditingController(text: category.nameEn);
    IconData selectedIcon = category.icon;
    Color selectedColor = category.color;
    final habitProvider = Provider.of<HabitDataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                    labelText: 'Arabic Name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: category.isCustom,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'English Name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: category.isCustom,
                ),
                if (!category.isCustom) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Default category names cannot be edited',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Icon: '),
                    IconButton(
                      icon: Icon(selectedIcon, color: selectedColor),
                      onPressed: () {
                        (context.findAncestorStateOfType<_CategoryManagementScreenState>())?._showIconPicker(context, (icon) {
                          setState(() {
                            selectedIcon = icon;
                          });
                        });
                      },
                    ),
                    const Spacer(),
                    const Text('Color: '),
                    GestureDetector(
                      onTap: () {
                        (context.findAncestorStateOfType<_CategoryManagementScreenState>())?._showColorPicker(context, (color) {
                          setState(() {
                            selectedColor = color;
                          });
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final updated = category.copyWith(
                  nameAr: nameArController.text,
                  nameEn: nameEnController.text,
                  icon: selectedIcon,
                  color: selectedColor,
                  updatedAt: DateTime.now(),
                );
                habitProvider.updateCategory(updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category updated successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, HabitCategory category) {
    final habitProvider = Provider.of<HabitDataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.nameEn}"? This will also delete all ${category.items.length} items in this category. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              habitProvider.deleteCategory(category.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category deleted successfully')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ItemsTab extends StatelessWidget {
  const _ItemsTab();

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitDataProvider>(context);
    final categories = habitProvider.categories;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.list_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a category first, then add items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, categoryIndex) {
        final category = categories[categoryIndex];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: Icon(category.icon, color: category.color),
            title: Text(category.nameEn),
            subtitle: Text('${category.items.length} items'),
            children: [
              if (category.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No items in this category'),
                ),
              ...category.items.map((item) {
                return ListTile(
                  title: Text(item.nameEn),
                  subtitle: Text(item.nameAr),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.isCustom)
                        Chip(
                          label: const Text('Custom'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(item.isEnabled ? Icons.visibility_off : Icons.visibility),
                                const SizedBox(width: 8),
                                Text(item.isEnabled ? 'Disable' : 'Enable'),
                              ],
                            ),
                          ),
                          if (item.isCustom)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditItemDialog(context, item, category);
                              break;
                            case 'toggle':
                              final updated = item.copyWith(
                                isEnabled: !item.isEnabled,
                                updatedAt: DateTime.now(),
                              );
                              habitProvider.updateItem(updated);
                              break;
                            case 'delete':
                              _showDeleteItemDialog(context, item);
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showEditItemDialog(BuildContext context, HabitItem item, HabitCategory category) {
    final nameArController = TextEditingController(text: item.nameAr);
    final nameEnController = TextEditingController(text: item.nameEn);
    final habitProvider = Provider.of<HabitDataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameArController,
              decoration: const InputDecoration(
                labelText: 'Arabic Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameEnController,
              decoration: const InputDecoration(
                labelText: 'English Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final updated = item.copyWith(
                nameAr: nameArController.text,
                nameEn: nameEnController.text,
                updatedAt: DateTime.now(),
              );
              habitProvider.updateItem(updated);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(BuildContext context, HabitItem item) {
    final habitProvider = Provider.of<HabitDataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.nameEn}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              habitProvider.deleteItem(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item deleted successfully')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
