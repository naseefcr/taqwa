import 'package:flutter/material.dart';

// Models
class HabitCategory {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final List<HabitItem> items;

  HabitCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class HabitItem {
  final String id;
  final String nameAr;
  final String nameEn;
  final String categoryId;
  final bool isCustom;

  HabitItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.categoryId,
    this.isCustom = false,
  });
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
  final Map<String, String> itemGrades; // itemId -> grade symbol
  final double percentage;

  DailyEntry({
    required this.date,
    required this.itemGrades,
    required this.percentage,
  });
}
