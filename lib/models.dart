import 'package:flutter/material.dart';

// Models
class HabitCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final List<HabitItem> items;
  final int order;
  final bool isCustom;
  final bool isEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HabitCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.items,
    this.order = 0,
    this.isCustom = false,
    this.isEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
      'colorValue': color.value,
      'order': order,
      'isCustom': isCustom,
      'isEnabled': isEnabled,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory HabitCategory.fromFirestore(Map<String, dynamic> data) {
    final iconCodePoint = data['iconCodePoint'] ?? Icons.category.codePoint;
    final iconFontFamily = data['iconFontFamily'] ?? 'MaterialIcons';
    final colorValue = data['colorValue'] ?? Colors.blue.value;
    
    return HabitCategory(
      id: data['id'] ?? '',
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      icon: _getIconFromData(iconCodePoint, iconFontFamily),
      color: Color(colorValue),
      items: [],
      order: data['order'] ?? 0,
      isCustom: data['isCustom'] ?? false,
      isEnabled: data['isEnabled'] ?? true,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
    );
  }

  static IconData _getIconFromData(int codePoint, String fontFamily) {
    return IconData(codePoint, fontFamily: fontFamily);
  }

  HabitCategory copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    IconData? icon,
    Color? color,
    List<HabitItem>? items,
    int? order,
    bool? isCustom,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitCategory(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      items: items ?? this.items,
      order: order ?? this.order,
      isCustom: isCustom ?? this.isCustom,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class HabitItem {
  final String id;
  final String nameAr;
  final String nameEn;
  final String categoryId;
  final int order;
  final bool isCustom;
  final bool isEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HabitItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.categoryId,
    this.order = 0,
    this.isCustom = false,
    this.isEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'categoryId': categoryId,
      'order': order,
      'isCustom': isCustom,
      'isEnabled': isEnabled,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory HabitItem.fromFirestore(Map<String, dynamic> data) {
    return HabitItem(
      id: data['id'] ?? '',
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      categoryId: data['categoryId'] ?? '',
      order: data['order'] ?? 0,
      isCustom: data['isCustom'] ?? false,
      isEnabled: data['isEnabled'] ?? true,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
    );
  }

  HabitItem copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? categoryId,
    int? order,
    bool? isCustom,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitItem(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      categoryId: categoryId ?? this.categoryId,
      order: order ?? this.order,
      isCustom: isCustom ?? this.isCustom,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Grade {
  final String symbol;
  final int value;
  final Color color;

  Grade({required this.symbol, required this.value, required this.color});

  static List<Grade> get allGrades => [
    Grade(symbol: 'A+', value: 10, color: Colors.green.shade700),
    Grade(symbol: 'A', value: 9, color: Colors.green.shade600),
    Grade(symbol: 'B+', value: 8, color: Colors.lightGreen.shade600),
    Grade(symbol: 'B', value: 7, color: Colors.lightGreen.shade500),
    Grade(symbol: 'C+', value: 6, color: Colors.orange.shade600),
    Grade(symbol: 'C', value: 5, color: Colors.orange.shade500),
    Grade(symbol: 'D+', value: 4, color: Colors.red.shade400),
    Grade(symbol: 'D', value: 0, color: Colors.red.shade600),
  ];
}

class DailyEntry {
  final DateTime date;
  final Map<String, String> itemGrades;
  final double percentage;

  DailyEntry({
    required this.date,
    required this.itemGrades,
    required this.percentage,
  });
}

class Template {
  final String id;
  final String nameEn;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final IconData icon;
  final List<CategoryTemplate> categories;

  Template({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.icon,
    required this.categories,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily ?? 'MaterialIcons',
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  factory Template.fromFirestore(Map<String, dynamic> data) {
    return Template(
      id: data['id'] ?? '',
      nameEn: data['nameEn'] ?? '',
      nameAr: data['nameAr'] ?? '',
      description: data['description'] ?? '',
      descriptionAr: data['descriptionAr'] ?? '',
      icon: IconData(
        data['iconCodePoint'] ?? Icons.category.codePoint,
        fontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      ),
      categories: (data['categories'] as List<dynamic>? ?? [])
          .map((c) => CategoryTemplate.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryTemplate {
  final String id;
  final String nameAr;
  final String nameEn;
  final int iconCodePoint;
  final String iconFontFamily;
  final int colorValue;
  final int order;
  final List<ItemTemplate> items;

  CategoryTemplate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.colorValue,
    required this.order,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'colorValue': colorValue,
      'order': order,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  factory CategoryTemplate.fromMap(Map<String, dynamic> data) {
    return CategoryTemplate(
      id: data['id'] ?? '',
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      iconCodePoint: data['iconCodePoint'] ?? Icons.category.codePoint,
      iconFontFamily: data['iconFontFamily'] ?? 'MaterialIcons',
      colorValue: data['colorValue'] ?? Colors.blue.value,
      order: data['order'] ?? 0,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => ItemTemplate.fromMap(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ItemTemplate {
  final String id;
  final String nameAr;
  final String nameEn;
  final int order;

  ItemTemplate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'order': order,
    };
  }

  factory ItemTemplate.fromMap(Map<String, dynamic> data) {
    return ItemTemplate(
      id: data['id'] ?? '',
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      order: data['order'] ?? 0,
    );
  }
}
