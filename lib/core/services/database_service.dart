import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/clip_item.dart';

/// NexusClip - خدمة قاعدة البيانات
/// Database Service
///
/// تدير تخزين واسترجاع عناصر الحافظة باستخدام Hive
/// Manages clipboard items storage and retrieval using Hive
///
/// Hive مثالي لهذا التطبيق لأنه:
/// - سريع جداً (O(1) للقراءة والكتابة)
/// - لا يحتاج اتصال بالإنترنت
/// - مناسب للبيانات المحلية
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // =====================================================
  // أسماء الصناديق / Box Names
  // =====================================================

  static const String _clipItemsBox = 'clip_items';
  static const String _settingsBox = 'settings';
  static const String _secureItemsBox = 'secure_items';

  // الصناديق / Boxes
  late Box<ClipItem> _clipBox;
  late Box<dynamic> _settingsBoxRef;
  late Box<String> _secureBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // =====================================================
  // التهيئة / Initialization
  // =====================================================

  /// تهيئة قاعدة البيانات
  /// Initialize database
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة Hive
      await Hive.initFlutter();

      // تسجيل المحولات
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ClipItemAdapter());
      }

      // فتح الصناديق
      _clipBox = await Hive.openBox<ClipItem>(_clipItemsBox);
      _settingsBoxRef = await Hive.openBox<dynamic>(_settingsBox);
      _secureBox = await Hive.openBox<String>(_secureItemsBox);

      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('Database initialized successfully');
        debugPrint('Total items: ${_clipBox.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing database: $e');
      }
      rethrow;
    }
  }

  /// إغلاق قاعدة البيانات
  /// Close database
  Future<void> close() async {
    await _clipBox.close();
    await _settingsBoxRef.close();
    await _secureBox.close();
    _isInitialized = false;
  }

  // =====================================================
  // عمليات CRUD للعناصر / CRUD Operations
  // =====================================================

  /// إضافة عنصر جديد
  /// Add new item
  Future<void> addItem(ClipItem item) async {
    // التحقق من التكرار
    final existing = _clipBox.values.where(
      (i) => i.content == item.content && !i.isDeleted,
    );

    if (existing.isNotEmpty) {
      // تحديث العنصر الموجود
      final existingItem = existing.first;
      existingItem.lastUsedAt = DateTime.now();
      existingItem.usageCount++;
      await existingItem.save();
      return;
    }

    // إضافة العنصر الجديد
    await _clipBox.put(item.id, item);

    // تنظيف العناصر القديمة إذا تجاوز الحد
    await _cleanupOldItems();
  }

  /// تحديث عنصر
  /// Update item
  Future<void> updateItem(ClipItem item) async {
    await _clipBox.put(item.id, item);
  }

  /// حذف عنصر (حذف ناعم)
  /// Delete item (soft delete)
  Future<void> deleteItem(String id) async {
    final item = _clipBox.get(id);
    if (item != null) {
      item.isDeleted = true;
      await item.save();
    }
  }

  /// حذف عنصر نهائياً
  /// Permanently delete item
  Future<void> permanentlyDeleteItem(String id) async {
    await _clipBox.delete(id);
  }

  /// استعادة عنصر محذوف
  /// Restore deleted item
  Future<void> restoreItem(String id) async {
    final item = _clipBox.get(id);
    if (item != null) {
      item.isDeleted = false;
      await item.save();
    }
  }

  /// الحصول على عنصر بالمعرف
  /// Get item by ID
  ClipItem? getItem(String id) {
    return _clipBox.get(id);
  }

  // =====================================================
  // استعلامات العناصر / Item Queries
  // =====================================================

  /// الحصول على جميع العناصر (غير المحذوفة)
  /// Get all items (not deleted)
  List<ClipItem> getAllItems() {
    return _clipBox.values
        .where((item) => !item.isDeleted)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// الحصول على آخر N عنصر
  /// Get last N items
  List<ClipItem> getRecentItems({int limit = 50}) {
    return getAllItems().take(limit).toList();
  }

  /// الحصول على العناصر المثبتة
  /// Get pinned items
  List<ClipItem> getPinnedItems() {
    return _clipBox.values
        .where((item) => item.isPinned && !item.isDeleted)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// الحصول على العناصر حسب النوع
  /// Get items by type
  List<ClipItem> getItemsByType(String type) {
    return _clipBox.values
        .where((item) => item.type == type && !item.isDeleted)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// البحث في العناصر
  /// Search items
  List<ClipItem> searchItems(String query) {
    if (query.isEmpty) return getAllItems();

    final lowercaseQuery = query.toLowerCase();
    return _clipBox.values
        .where((item) =>
            !item.isDeleted &&
            (item.content.toLowerCase().contains(lowercaseQuery) ||
                (item.label?.toLowerCase().contains(lowercaseQuery) ?? false)))
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// الحصول على القوالب
  /// Get templates
  List<ClipItem> getTemplates() {
    return getItemsByType('template');
  }

  /// الحصول على الروابط
  /// Get links
  List<ClipItem> getLinks() {
    return getItemsByType('link');
  }

  /// الحصول على الأكواد
  /// Get code snippets
  List<ClipItem> getCodeSnippets() {
    return getItemsByType('code');
  }

  /// الحصول على كلمات المرور
  /// Get passwords
  List<ClipItem> getSecureItems() {
    return _clipBox.values
        .where((item) => item.isSecure && !item.isDeleted)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  /// الحصول على العناصر المحذوفة
  /// Get deleted items
  List<ClipItem> getDeletedItems() {
    return _clipBox.values
        .where((item) => item.isDeleted)
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  }

  // =====================================================
  // تنظيف البيانات / Data Cleanup
  // =====================================================

  /// تنظيف العناصر القديمة
  /// Cleanup old items
  Future<void> _cleanupOldItems() async {
    const maxItems = 500;
    final items = getAllItems();

    if (items.length > maxItems) {
      // حذف العناصر غير المثبتة الأقدم
      final toDelete = items
          .where((item) => !item.isPinned)
          .skip(maxItems)
          .toList();

      for (final item in toDelete) {
        await permanentlyDeleteItem(item.id);
      }
    }
  }

  /// حذف جميع العناصر المحذوفة نهائياً
  /// Permanently delete all deleted items
  Future<void> emptyTrash() async {
    final deletedItems = getDeletedItems();
    for (final item in deletedItems) {
      await permanentlyDeleteItem(item.id);
    }
  }

  /// مسح جميع البيانات
  /// Clear all data
  Future<void> clearAllData() async {
    await _clipBox.clear();
  }

  // =====================================================
  // الإعدادات / Settings
  // =====================================================

  /// حفظ إعداد
  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBoxRef.put(key, value);
  }

  /// الحصول على إعداد
  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBoxRef.get(key, defaultValue: defaultValue) as T?;
  }

  /// حذف إعداد
  /// Delete setting
  Future<void> deleteSetting(String key) async {
    await _settingsBoxRef.delete(key);
  }

  // =====================================================
  // الإحصائيات / Statistics
  // =====================================================

  /// الحصول على إحصائيات
  /// Get statistics
  Map<String, int> getStatistics() {
    final items = getAllItems();
    
    return {
      'total': items.length,
      'text': items.where((i) => i.type == 'text').length,
      'code': items.where((i) => i.type == 'code').length,
      'links': items.where((i) => i.type == 'link').length,
      'passwords': items.where((i) => i.type == 'password').length,
      'templates': items.where((i) => i.type == 'template').length,
      'emails': items.where((i) => i.type == 'email').length,
      'phones': items.where((i) => i.type == 'phone').length,
      'pinned': items.where((i) => i.isPinned).length,
      'deleted': getDeletedItems().length,
    };
  }

  /// الحصول على العناصر الأكثر استخداماً
  /// Get most used items
  List<ClipItem> getMostUsedItems({int limit = 10}) {
    return getAllItems()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  // =====================================================
  // التصدير والاستيراد / Export & Import
  // =====================================================

  /// تصدير البيانات
  /// Export data
  List<Map<String, dynamic>> exportData() {
    return getAllItems().map((item) => item.toMap()).toList();
  }

  /// استيراد البيانات
  /// Import data
  Future<int> importData(List<Map<String, dynamic>> data) async {
    int imported = 0;
    
    for (final itemMap in data) {
      try {
        final item = ClipItem.fromMap(itemMap);
        await addItem(item);
        imported++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error importing item: $e');
        }
      }
    }
    
    return imported;
  }
}
