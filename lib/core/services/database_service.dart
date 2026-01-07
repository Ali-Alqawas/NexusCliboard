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
  Box<ClipItem>? _clipBox;
  Box<dynamic>? _settingsBoxRef;
  Box<String>? _secureBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // حالة التهيئة / Initialization state
  bool _isInitializing = false;
  String? _lastError;
  String? get lastError => _lastError;

  // =====================================================
  // التهيئة / Initialization
  // =====================================================

  /// تهيئة قاعدة البيانات
  /// Initialize database
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // انتظار حتى انتهاء التهيئة الحالية
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    _lastError = null;

    try {
      // تهيئة Hive
      await Hive.initFlutter();

      // تسجيل المحولات
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ClipItemAdapter());
      }

      // فتح الصناديق مع معالجة الأخطاء
      try {
        _clipBox = await Hive.openBox<ClipItem>(_clipItemsBox);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error opening clip_items box: $e');
        }
        // محاولة حذف الصندوق التالف وإعادة فتحه
        await Hive.deleteBoxFromDisk(_clipItemsBox);
        _clipBox = await Hive.openBox<ClipItem>(_clipItemsBox);
      }

      try {
        _settingsBoxRef = await Hive.openBox<dynamic>(_settingsBox);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error opening settings box: $e');
        }
        await Hive.deleteBoxFromDisk(_settingsBox);
        _settingsBoxRef = await Hive.openBox<dynamic>(_settingsBox);
      }

      try {
        _secureBox = await Hive.openBox<String>(_secureItemsBox);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error opening secure_items box: $e');
        }
        await Hive.deleteBoxFromDisk(_secureItemsBox);
        _secureBox = await Hive.openBox<String>(_secureItemsBox);
      }

      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('Database initialized successfully');
        debugPrint('Total items: ${_clipBox?.length ?? 0}');
      }
    } catch (e, stack) {
      _lastError = e.toString();
      if (kDebugMode) {
        debugPrint('Error initializing database: $e');
        debugPrint('Stack: $stack');
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// إغلاق قاعدة البيانات
  /// Close database
  Future<void> close() async {
    try {
      if (_clipBox?.isOpen == true) {
        await _clipBox?.close();
      }
      if (_settingsBoxRef?.isOpen == true) {
        await _settingsBoxRef?.close();
      }
      if (_secureBox?.isOpen == true) {
        await _secureBox?.close();
      }
      _isInitialized = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error closing database: $e');
      }
    }
  }

  /// إعادة تهيئة قاعدة البيانات
  /// Reinitialize database
  Future<void> reinitialize() async {
    await close();
    _isInitialized = false;
    await initialize();
  }

  // =====================================================
  // التحقق من الصلاحية / Validation
  // =====================================================

  void _ensureInitialized() {
    if (!_isInitialized || _clipBox == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
  }

  bool _isBoxReady() {
    return _isInitialized && _clipBox != null && _clipBox!.isOpen;
  }

  // =====================================================
  // عمليات CRUD للعناصر / CRUD Operations
  // =====================================================

  /// إضافة عنصر جديد
  /// Add new item
  Future<void> addItem(ClipItem item) async {
    if (!_isBoxReady()) {
      await initialize();
    }
    _ensureInitialized();

    try {
      // التحقق من التكرار
      final existing = _clipBox!.values.where(
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
      await _clipBox!.put(item.id, item);

      // تنظيف العناصر القديمة إذا تجاوز الحد
      await _cleanupOldItems();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding item: $e');
      }
      rethrow;
    }
  }

  /// تحديث عنصر
  /// Update item
  Future<void> updateItem(ClipItem item) async {
    if (!_isBoxReady()) {
      await initialize();
    }
    _ensureInitialized();

    try {
      await _clipBox!.put(item.id, item);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating item: $e');
      }
      rethrow;
    }
  }

  /// حذف عنصر (حذف ناعم)
  /// Delete item (soft delete)
  Future<void> deleteItem(String id) async {
    if (!_isBoxReady()) {
      await initialize();
    }
    _ensureInitialized();

    try {
      final item = _clipBox!.get(id);
      if (item != null) {
        item.isDeleted = true;
        await item.save();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting item: $e');
      }
      rethrow;
    }
  }

  /// حذف عنصر نهائياً
  /// Permanently delete item
  Future<void> permanentlyDeleteItem(String id) async {
    if (!_isBoxReady()) {
      await initialize();
    }
    _ensureInitialized();

    try {
      await _clipBox!.delete(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error permanently deleting item: $e');
      }
      rethrow;
    }
  }

  /// استعادة عنصر محذوف
  /// Restore deleted item
  Future<void> restoreItem(String id) async {
    if (!_isBoxReady()) {
      await initialize();
    }
    _ensureInitialized();

    try {
      final item = _clipBox!.get(id);
      if (item != null) {
        item.isDeleted = false;
        await item.save();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error restoring item: $e');
      }
      rethrow;
    }
  }

  /// الحصول على عنصر بالمعرف
  /// Get item by ID
  ClipItem? getItem(String id) {
    if (!_isBoxReady()) {
      return null;
    }
    try {
      return _clipBox!.get(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting item: $e');
      }
      return null;
    }
  }

  // =====================================================
  // استعلامات العناصر / Item Queries
  // =====================================================

  /// الحصول على جميع العناصر (غير المحذوفة)
  /// Get all items (not deleted)
  List<ClipItem> getAllItems() {
    if (!_isBoxReady()) {
      return [];
    }
    
    try {
      return _clipBox!.values
          .where((item) => !item.isDeleted)
          .toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all items: $e');
      }
      return [];
    }
  }

  /// الحصول على آخر N عنصر
  /// Get last N items
  List<ClipItem> getRecentItems({int limit = 50}) {
    return getAllItems().take(limit).toList();
  }

  /// الحصول على العناصر المثبتة
  /// Get pinned items
  List<ClipItem> getPinnedItems() {
    if (!_isBoxReady()) {
      return [];
    }
    
    try {
      return _clipBox!.values
          .where((item) => item.isPinned && !item.isDeleted)
          .toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pinned items: $e');
      }
      return [];
    }
  }

  /// الحصول على العناصر حسب النوع
  /// Get items by type
  List<ClipItem> getItemsByType(String type) {
    if (!_isBoxReady()) {
      return [];
    }
    
    try {
      return _clipBox!.values
          .where((item) => item.type == type && !item.isDeleted)
          .toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting items by type: $e');
      }
      return [];
    }
  }

  /// البحث في العناصر
  /// Search items
  List<ClipItem> searchItems(String query) {
    if (!_isBoxReady()) {
      return [];
    }
    
    if (query.isEmpty) return getAllItems();

    try {
      final lowercaseQuery = query.toLowerCase();
      return _clipBox!.values
          .where((item) =>
              !item.isDeleted &&
              (item.content.toLowerCase().contains(lowercaseQuery) ||
                  (item.label?.toLowerCase().contains(lowercaseQuery) ?? false)))
          .toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching items: $e');
      }
      return [];
    }
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
    if (!_isBoxReady()) {
      return [];
    }
    
    try {
      return _clipBox!.values
          .where((item) => item.isSecure && !item.isDeleted)
          .toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting secure items: $e');
      }
      return [];
    }
  }

  /// الحصول على العناصر المحذوفة
  /// Get deleted items
  List<ClipItem> getDeletedItems() {
    if (!_isBoxReady()) {
      return [];
    }
    
    try {
      return _clipBox!.values
          .where((item) => item.isDeleted)
          .toList()
        ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting deleted items: $e');
      }
      return [];
    }
  }

  // =====================================================
  // تنظيف البيانات / Data Cleanup
  // =====================================================

  /// تنظيف العناصر القديمة
  /// Cleanup old items
  Future<void> _cleanupOldItems() async {
    if (!_isBoxReady()) return;
    
    try {
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cleaning up old items: $e');
      }
    }
  }

  /// حذف جميع العناصر المحذوفة نهائياً
  /// Permanently delete all deleted items
  Future<void> emptyTrash() async {
    if (!_isBoxReady()) return;
    
    try {
      final deletedItems = getDeletedItems();
      for (final item in deletedItems) {
        await permanentlyDeleteItem(item.id);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error emptying trash: $e');
      }
      rethrow;
    }
  }

  /// مسح جميع البيانات
  /// Clear all data
  Future<void> clearAllData() async {
    if (!_isBoxReady()) return;
    
    try {
      await _clipBox!.clear();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing all data: $e');
      }
      rethrow;
    }
  }

  // =====================================================
  // الإعدادات / Settings
  // =====================================================

  /// حفظ إعداد
  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    if (_settingsBoxRef == null || !_settingsBoxRef!.isOpen) {
      return;
    }
    
    try {
      await _settingsBoxRef!.put(key, value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving setting: $e');
      }
    }
  }

  /// الحصول على إعداد
  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (_settingsBoxRef == null || !_settingsBoxRef!.isOpen) {
      return defaultValue;
    }
    
    try {
      return _settingsBoxRef!.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting setting: $e');
      }
      return defaultValue;
    }
  }

  /// حذف إعداد
  /// Delete setting
  Future<void> deleteSetting(String key) async {
    if (_settingsBoxRef == null || !_settingsBoxRef!.isOpen) {
      return;
    }
    
    try {
      await _settingsBoxRef!.delete(key);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting setting: $e');
      }
    }
  }

  // =====================================================
  // الإحصائيات / Statistics
  // =====================================================

  /// الحصول على إحصائيات
  /// Get statistics
  Map<String, int> getStatistics() {
    if (!_isBoxReady()) {
      return {
        'total': 0,
        'text': 0,
        'code': 0,
        'links': 0,
        'passwords': 0,
        'templates': 0,
        'emails': 0,
        'phones': 0,
        'pinned': 0,
        'deleted': 0,
      };
    }
    
    try {
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting statistics: $e');
      }
      return {
        'total': 0,
        'text': 0,
        'code': 0,
        'links': 0,
        'passwords': 0,
        'templates': 0,
        'emails': 0,
        'phones': 0,
        'pinned': 0,
        'deleted': 0,
      };
    }
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
    try {
      return getAllItems().map((item) => item.toMap()).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting data: $e');
      }
      return [];
    }
  }

  /// استيراد البيانات
  /// Import data
  Future<int> importData(List<Map<String, dynamic>> data) async {
    if (!_isBoxReady()) {
      await initialize();
    }
    
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
