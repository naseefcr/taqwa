import 'package:flutter/material.dart';
import '../models.dart';

class HabitTemplates {
  static List<Template> getAllTemplates() {
    return [
      _getDefaultIslamicTemplate(),
      _getPrayerFocusedTemplate(),
      _getQuranJourneyTemplate(),
      _getMinimalistTemplate(),
      _getBlankTemplate(),
    ];
  }

  static Template _getDefaultIslamicTemplate() {
    return Template(
      id: 'default_islamic',
      nameEn: 'Default Islamic Tracker',
      nameAr: 'المتتبع الإسلامي الافتراضي',
      description: 'Comprehensive Islamic habit tracker with prayers, Quran, and character development',
      descriptionAr: 'متتبع شامل للعادات الإسلامية مع الصلوات والقرآن وتطوير الشخصية',
      icon: Icons.mosque,
      categories: [
        CategoryTemplate(
          id: 'amal',
          nameAr: 'أعمال',
          nameEn: 'Worship',
          iconCodePoint: Icons.mosque.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.green.value,
          order: 0,
          items: [
            ItemTemplate(id: 'maghrib', nameAr: 'مغرب', nameEn: 'Maghrib', order: 0),
            ItemTemplate(id: 'isha', nameAr: 'عشاء', nameEn: 'Isha', order: 1),
            ItemTemplate(id: 'tahajjud', nameAr: 'تهجد', nameEn: 'Tahajjud', order: 2),
            ItemTemplate(id: 'fajr', nameAr: 'فجر', nameEn: 'Fajr', order: 3),
            ItemTemplate(id: 'ishraq', nameAr: 'إشراق', nameEn: 'Ishraq', order: 4),
            ItemTemplate(id: 'dhuhr', nameAr: 'ظهر', nameEn: 'Dhuhr', order: 5),
            ItemTemplate(id: 'asr', nameAr: 'عصر', nameEn: 'Asr', order: 6),
            ItemTemplate(id: 'evening_dhikr', nameAr: 'أذكار المساء', nameEn: 'Evening Dhikr', order: 7),
            ItemTemplate(id: 'morning_dhikr', nameAr: 'أذكار أصبح', nameEn: 'Morning Dhikr', order: 8),
            ItemTemplate(id: 'sunnah_12', nameAr: '١٢ ركعة رواتب', nameEn: '12 Sunnah Rakahs', order: 9),
          ],
        ),
        CategoryTemplate(
          id: 'quran',
          nameAr: 'قرآن',
          nameEn: 'Quran',
          iconCodePoint: Icons.menu_book.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.blue.value,
          order: 1,
          items: [
            ItemTemplate(id: 'four_surahs', nameAr: '٤ سوره', nameEn: '4 Surahs', order: 0),
            ItemTemplate(id: 'amkhta', nameAr: 'امختہ', nameEn: 'Amkhta', order: 1),
            ItemTemplate(id: 'mushaf', nameAr: 'مصحف', nameEn: 'Mushaf', order: 2),
          ],
        ),
        CategoryTemplate(
          id: 'career',
          nameAr: 'مهنة',
          nameEn: 'Career',
          iconCodePoint: Icons.work.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.purple.value,
          order: 2,
          items: [
            ItemTemplate(id: 'tym', nameAr: 'TYM', nameEn: 'TYM', order: 0),
          ],
        ),
        CategoryTemplate(
          id: 'study',
          nameAr: 'دراسة',
          nameEn: 'Study',
          iconCodePoint: Icons.school.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.orange.value,
          order: 3,
          items: [
            ItemTemplate(id: 'seerah', nameAr: 'سيرة', nameEn: 'Seerah', order: 0),
          ],
        ),
        CategoryTemplate(
          id: 'home',
          nameAr: 'البيت',
          nameEn: 'Home',
          iconCodePoint: Icons.home.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.teal.value,
          order: 4,
          items: [
            ItemTemplate(id: 'dress', nameAr: 'لباس', nameEn: 'Dress', order: 0),
            ItemTemplate(id: 'agriculture', nameAr: 'زراعة', nameEn: 'Agriculture', order: 1),
            ItemTemplate(id: 'newspaper', nameAr: 'جريدة', nameEn: 'Newspaper', order: 2),
            ItemTemplate(id: 'clean', nameAr: 'تنظيف', nameEn: 'Clean', order: 3),
          ],
        ),
        CategoryTemplate(
          id: 'avoid',
          nameAr: 'تجنب غير المرغوب',
          nameEn: 'Avoid Unwanted',
          iconCodePoint: Icons.block.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.red.value,
          order: 5,
          items: [
            ItemTemplate(id: 'food_control', nameAr: 'طعام', nameEn: 'Food Control', order: 0),
            ItemTemplate(id: 'sleep_control', nameAr: 'نوم', nameEn: 'Sleep Control', order: 1),
            ItemTemplate(id: 'phone_control', nameAr: 'هاتف', nameEn: 'Phone Control', order: 2),
            ItemTemplate(id: 'talk_control', nameAr: 'كلام', nameEn: 'Talk Control', order: 3),
            ItemTemplate(id: 'p_control', nameAr: 'P', nameEn: 'P Control', order: 4),
          ],
        ),
        CategoryTemplate(
          id: 'dawah',
          nameAr: 'دعوة',
          nameEn: 'Dawah',
          iconCodePoint: Icons.campaign.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.indigo.value,
          order: 6,
          items: [
            ItemTemplate(id: 'fill_ontime', nameAr: 'Fill Ontime', nameEn: 'Fill Ontime', order: 0),
            ItemTemplate(id: 'heart_clean', nameAr: 'Heart clean before sleep', nameEn: 'Heart Clean Before Sleep', order: 1),
            ItemTemplate(id: 'class_fikr', nameAr: 'Class/ Fikr Paloth H/Mahal', nameEn: 'Class/Fikr', order: 2),
          ],
        ),
      ],
    );
  }

  static Template _getPrayerFocusedTemplate() {
    return Template(
      id: 'prayer_focused',
      nameEn: 'Prayer Focused',
      nameAr: 'التركيز على الصلاة',
      description: 'Focus on establishing and perfecting the five daily prayers with sunnah',
      descriptionAr: 'التركيز على إقامة وإتقان الصلوات الخمس اليومية مع السنن',
      icon: Icons.access_time,
      categories: [
        CategoryTemplate(
          id: 'fard_prayers',
          nameAr: 'صلوات فرض',
          nameEn: 'Obligatory Prayers',
          iconCodePoint: Icons.mosque.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.green.value,
          order: 0,
          items: [
            ItemTemplate(id: 'fajr', nameAr: 'فجر', nameEn: 'Fajr', order: 0),
            ItemTemplate(id: 'dhuhr', nameAr: 'ظهر', nameEn: 'Dhuhr', order: 1),
            ItemTemplate(id: 'asr', nameAr: 'عصر', nameEn: 'Asr', order: 2),
            ItemTemplate(id: 'maghrib', nameAr: 'مغرب', nameEn: 'Maghrib', order: 3),
            ItemTemplate(id: 'isha', nameAr: 'عشاء', nameEn: 'Isha', order: 4),
          ],
        ),
        CategoryTemplate(
          id: 'sunnah_prayers',
          nameAr: 'صلوات سنة',
          nameEn: 'Sunnah Prayers',
          iconCodePoint: Icons.star.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.blue.value,
          order: 1,
          items: [
            ItemTemplate(id: 'sunnah_12', nameAr: '١٢ ركعة رواتب', nameEn: '12 Sunnah Rakahs', order: 0),
            ItemTemplate(id: 'tahajjud', nameAr: 'تهجد', nameEn: 'Tahajjud', order: 1),
            ItemTemplate(id: 'ishraq', nameAr: 'إشراق', nameEn: 'Ishraq', order: 2),
            ItemTemplate(id: 'duha', nameAr: 'ضحى', nameEn: 'Duha', order: 3),
          ],
        ),
        CategoryTemplate(
          id: 'dhikr',
          nameAr: 'ذكر',
          nameEn: 'Dhikr',
          iconCodePoint: Icons.record_voice_over.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.purple.value,
          order: 2,
          items: [
            ItemTemplate(id: 'morning_dhikr', nameAr: 'أذكار الصباح', nameEn: 'Morning Dhikr', order: 0),
            ItemTemplate(id: 'evening_dhikr', nameAr: 'أذكار المساء', nameEn: 'Evening Dhikr', order: 1),
          ],
        ),
      ],
    );
  }

  static Template _getQuranJourneyTemplate() {
    return Template(
      id: 'quran_journey',
      nameEn: 'Quran Journey',
      nameAr: 'رحلة القرآن',
      description: 'Dedicated to Quran recitation, memorization, and understanding',
      descriptionAr: 'مخصص لتلاوة القرآن والحفظ والفهم',
      icon: Icons.menu_book,
      categories: [
        CategoryTemplate(
          id: 'recitation',
          nameAr: 'تلاوة',
          nameEn: 'Recitation',
          iconCodePoint: Icons.menu_book.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.green.value,
          order: 0,
          items: [
            ItemTemplate(id: 'one_juz', nameAr: 'جزء واحد', nameEn: 'One Juz', order: 0),
            ItemTemplate(id: 'half_juz', nameAr: 'نصف جزء', nameEn: 'Half Juz', order: 1),
            ItemTemplate(id: 'four_surahs', nameAr: '٤ سور', nameEn: '4 Surahs', order: 2),
          ],
        ),
        CategoryTemplate(
          id: 'memorization',
          nameAr: 'حفظ',
          nameEn: 'Memorization',
          iconCodePoint: Icons.psychology.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.blue.value,
          order: 1,
          items: [
            ItemTemplate(id: 'new_ayah', nameAr: 'آية جديدة', nameEn: 'New Ayah', order: 0),
            ItemTemplate(id: 'review_page', nameAr: 'مراجعة صفحة', nameEn: 'Review Page', order: 1),
            ItemTemplate(id: 'amkhta', nameAr: 'امختہ', nameEn: 'Amkhta', order: 2),
          ],
        ),
        CategoryTemplate(
          id: 'understanding',
          nameAr: 'فهم',
          nameEn: 'Understanding',
          iconCodePoint: Icons.lightbulb.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.orange.value,
          order: 2,
          items: [
            ItemTemplate(id: 'tafsir', nameAr: 'تفسير', nameEn: 'Tafsir', order: 0),
            ItemTemplate(id: 'translation', nameAr: 'ترجمة', nameEn: 'Translation', order: 1),
          ],
        ),
        CategoryTemplate(
          id: 'essential_prayers',
          nameAr: 'صلوات أساسية',
          nameEn: 'Essential Prayers',
          iconCodePoint: Icons.mosque.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.teal.value,
          order: 3,
          items: [
            ItemTemplate(id: 'fajr', nameAr: 'فجر', nameEn: 'Fajr', order: 0),
            ItemTemplate(id: 'dhuhr', nameAr: 'ظهر', nameEn: 'Dhuhr', order: 1),
            ItemTemplate(id: 'asr', nameAr: 'عصر', nameEn: 'Asr', order: 2),
            ItemTemplate(id: 'maghrib', nameAr: 'مغرب', nameEn: 'Maghrib', order: 3),
            ItemTemplate(id: 'isha', nameAr: 'عشاء', nameEn: 'Isha', order: 4),
          ],
        ),
      ],
    );
  }

  static Template _getMinimalistTemplate() {
    return Template(
      id: 'minimalist',
      nameEn: 'Minimalist',
      nameAr: 'البسيط',
      description: 'Essential Islamic habits only - perfect for beginners',
      descriptionAr: 'العادات الإسلامية الأساسية فقط - مثالي للمبتدئين',
      icon: Icons.filter_list,
      categories: [
        CategoryTemplate(
          id: 'prayers',
          nameAr: 'صلوات',
          nameEn: 'Prayers',
          iconCodePoint: Icons.mosque.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.green.value,
          order: 0,
          items: [
            ItemTemplate(id: 'fajr', nameAr: 'فجر', nameEn: 'Fajr', order: 0),
            ItemTemplate(id: 'dhuhr', nameAr: 'ظهر', nameEn: 'Dhuhr', order: 1),
            ItemTemplate(id: 'asr', nameAr: 'عصر', nameEn: 'Asr', order: 2),
            ItemTemplate(id: 'maghrib', nameAr: 'مغرب', nameEn: 'Maghrib', order: 3),
            ItemTemplate(id: 'isha', nameAr: 'عشاء', nameEn: 'Isha', order: 4),
          ],
        ),
        CategoryTemplate(
          id: 'quran',
          nameAr: 'قرآن',
          nameEn: 'Quran',
          iconCodePoint: Icons.menu_book.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.blue.value,
          order: 1,
          items: [
            ItemTemplate(id: 'quran_reading', nameAr: 'قراءة القرآن', nameEn: 'Quran Reading', order: 0),
          ],
        ),
        CategoryTemplate(
          id: 'dhikr',
          nameAr: 'ذكر',
          nameEn: 'Dhikr',
          iconCodePoint: Icons.record_voice_over.codePoint,
          iconFontFamily: 'MaterialIcons',
          colorValue: Colors.purple.value,
          order: 2,
          items: [
            ItemTemplate(id: 'morning_dhikr', nameAr: 'أذكار الصباح', nameEn: 'Morning Dhikr', order: 0),
            ItemTemplate(id: 'evening_dhikr', nameAr: 'أذكار المساء', nameEn: 'Evening Dhikr', order: 1),
          ],
        ),
      ],
    );
  }

  static Template _getBlankTemplate() {
    return Template(
      id: 'blank',
      nameEn: 'Start from Scratch',
      nameAr: 'ابدأ من الصفر',
      description: 'Create your own custom habit tracker from scratch',
      descriptionAr: 'أنشئ متتبع العادات المخصص الخاص بك من الصفر',
      icon: Icons.add_box,
      categories: [],
    );
  }

  static Template getTemplateById(String id) {
    return getAllTemplates().firstWhere(
      (template) => template.id == id,
      orElse: () => _getDefaultIslamicTemplate(),
    );
  }
}
