import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// NexusClip - خدمة المنصة
/// Platform Service
///
/// الجسر بين Flutter و Native Kotlin
/// Bridge between Flutter and Native Kotlin
///
/// المسؤوليات / Responsibilities:
/// - إدارة الخدمة الأمامية (Foreground Service)
/// - التحقق من الصلاحيات
/// - التحكم بالمؤشر عبر Virtual D-Pad
/// - إدارة المقبض الجانبي
class PlatformService {
  // Singleton pattern
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  // =====================================================
  // قنوات الاتصال / Communication Channels
  // =====================================================

  /// قناة الأساليب الرئيسية
  /// Main method channel
  static const MethodChannel _methodChannel = MethodChannel(
    'com.nexusclip.clip/methods',
  );

  /// قناة الأحداث
  /// Event channel
  static const EventChannel _eventChannel = EventChannel(
    'com.nexusclip.clip/events',
  );

  /// قناة الحافظة
  /// Clipboard channel
  static const MethodChannel _clipboardChannel = MethodChannel(
    'com.nexusclip.clip/clipboard',
  );

  // =====================================================
  // حالة الخدمة / Service State
  // =====================================================

  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  bool _hasOverlayPermission = false;
  bool get hasOverlayPermission => _hasOverlayPermission;

  bool _hasAccessibilityPermission = false;
  bool get hasAccessibilityPermission => _hasAccessibilityPermission;

  // بث الأحداث / Event stream
  Stream<dynamic>? _eventStream;
  StreamSubscription<dynamic>? _eventSubscription;

  // =====================================================
  // التهيئة / Initialization
  // =====================================================

  /// تهيئة الخدمة
  /// Initialize service
  Future<void> initialize() async {
    // التحقق من الصلاحيات
    await checkAllPermissions();

    // الاستماع للأحداث
    _eventStream = _eventChannel.receiveBroadcastStream();
    _eventSubscription = _eventStream?.listen(_handleEvent);

    // محاولة بدء الخدمة إذا كانت الصلاحيات موجودة
    if (_hasOverlayPermission) {
      await startService();
    }
  }

  /// التخلص من الموارد
  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
  }

  // =====================================================
  // معالجة الأحداث / Event Handling
  // =====================================================

  void _handleEvent(dynamic event) {
    if (event is Map<String, dynamic>) {
      final eventType = event['event'] as String?;

      switch (eventType) {
        case 'permissionResult':
          _handlePermissionResult(event);
          break;
        case 'permissionsUpdated':
          _updatePermissions(event);
          break;
        case 'clipboardChanged':
          _handleClipboardChange(event);
          break;
        case 'handleTapped':
          _handleHandleTap(event);
          break;
      }
    }
  }

  void _handlePermissionResult(Map<String, dynamic> event) {
    final permission = event['permission'] as String?;
    final granted = event['granted'] as bool? ?? false;

    if (permission == 'overlay') {
      _hasOverlayPermission = granted;
    } else if (permission == 'accessibility') {
      _hasAccessibilityPermission = granted;
    }
  }

  void _updatePermissions(Map<String, dynamic> event) {
    _hasOverlayPermission = event['overlay'] as bool? ?? false;
    _hasAccessibilityPermission = event['accessibility'] as bool? ?? false;
  }

  void _handleClipboardChange(Map<String, dynamic> event) {
    // يمكن إضافة معالجة إضافية هنا
    // Additional handling can be added here
  }

  void _handleHandleTap(Map<String, dynamic> event) {
    // يمكن إضافة معالجة إضافية هنا
    // Additional handling can be added here
  }

  // =====================================================
  // إدارة الخدمة / Service Management
  // =====================================================

  /// بدء الخدمة الأمامية
  /// Start foreground service
  Future<bool> startService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startService');
      _isServiceRunning = result ?? false;
      return _isServiceRunning;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting service: ${e.message}');
      }
      return false;
    }
  }

  /// إيقاف الخدمة
  /// Stop service
  Future<bool> stopService() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopService');
      _isServiceRunning = !(result ?? true);
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error stopping service: ${e.message}');
      }
      return false;
    }
  }

  /// التحقق من حالة الخدمة
  /// Check service status
  Future<bool> checkServiceStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isServiceRunning');
      _isServiceRunning = result ?? false;
      return _isServiceRunning;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking service status: ${e.message}');
      }
      return false;
    }
  }

  // =====================================================
  // الصلاحيات / Permissions
  // =====================================================

  /// التحقق من جميع الصلاحيات
  /// Check all permissions
  Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'checkAllPermissions',
      );
      
      if (result != null) {
        _hasOverlayPermission = result['overlay'] as bool? ?? false;
        _hasAccessibilityPermission = result['accessibility'] as bool? ?? false;
      }
      
      return {
        'overlay': _hasOverlayPermission,
        'accessibility': _hasAccessibilityPermission,
      };
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking permissions: ${e.message}');
      }
      return {'overlay': false, 'accessibility': false};
    }
  }

  /// التحقق من صلاحية العرض فوق التطبيقات
  /// Check overlay permission
  Future<bool> checkOverlayPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'checkOverlayPermission',
      );
      _hasOverlayPermission = result ?? false;
      return _hasOverlayPermission;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking overlay permission: ${e.message}');
      }
      return false;
    }
  }

  /// طلب صلاحية العرض فوق التطبيقات
  /// Request overlay permission
  Future<void> requestOverlayPermission() async {
    try {
      await _methodChannel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting overlay permission: ${e.message}');
      }
    }
  }

  /// التحقق من صلاحية خدمة الوصول
  /// Check accessibility permission
  Future<bool> checkAccessibilityPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'checkAccessibilityPermission',
      );
      _hasAccessibilityPermission = result ?? false;
      return _hasAccessibilityPermission;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking accessibility permission: ${e.message}');
      }
      return false;
    }
  }

  /// طلب صلاحية خدمة الوصول
  /// Request accessibility permission
  Future<void> requestAccessibilityPermission() async {
    try {
      await _methodChannel.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting accessibility permission: ${e.message}');
      }
    }
  }

  // =====================================================
  // التحكم بالمؤشر / Cursor Control
  // =====================================================

  /// تحريك المؤشر
  /// Move cursor
  Future<bool> moveCursor(CursorDirection direction) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('moveCursor', {
        'direction': direction.name,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error moving cursor: ${e.message}');
      }
      return false;
    }
  }

  /// إرسال حدث زر
  /// Send key event
  Future<bool> sendKeyEvent(int keyCode) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('sendKeyEvent', {
        'keyCode': keyCode,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending key event: ${e.message}');
      }
      return false;
    }
  }

  // =====================================================
  // المقبض الجانبي / Side Handle
  // =====================================================

  /// إظهار المقبض
  /// Show handle
  Future<bool> showHandle() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('showHandle');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing handle: ${e.message}');
      }
      return false;
    }
  }

  /// إخفاء المقبض
  /// Hide handle
  Future<bool> hideHandle() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('hideHandle');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error hiding handle: ${e.message}');
      }
      return false;
    }
  }

  /// تعيين موضع المقبض
  /// Set handle position
  Future<bool> setHandlePosition(double y) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'setHandlePosition',
        {'y': y},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting handle position: ${e.message}');
      }
      return false;
    }
  }

  // =====================================================
  // الحافظة / Clipboard
  // =====================================================

  /// الحصول على محتوى الحافظة
  /// Get clipboard content
  Future<String?> getClipboardContent() async {
    try {
      final result = await _clipboardChannel.invokeMethod<String>(
        'getClipboardContent',
      );
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting clipboard content: ${e.message}');
      }
      return null;
    }
  }

  /// تعيين محتوى الحافظة
  /// Set clipboard content
  Future<bool> setClipboardContent(String text) async {
    try {
      final result = await _clipboardChannel.invokeMethod<bool>(
        'setClipboardContent',
        {'text': text},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting clipboard content: ${e.message}');
      }
      return false;
    }
  }

  /// الحصول على سجل الحافظة
  /// Get clipboard history
  Future<List<Map<String, dynamic>>> getClipboardHistory() async {
    try {
      final result = await _clipboardChannel.invokeMethod<List<dynamic>>(
        'getClipboardHistory',
      );
      
      return result?.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList() ?? [];
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting clipboard history: ${e.message}');
      }
      return [];
    }
  }

  // =====================================================
  // معلومات الجهاز / Device Info
  // =====================================================

  /// الحصول على معلومات الجهاز
  /// Get device info
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceInfo',
      );
      
      return result?.map((key, value) => MapEntry(key.toString(), value)) ?? {};
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting device info: ${e.message}');
      }
      return {};
    }
  }
}

/// اتجاهات المؤشر
/// Cursor directions
enum CursorDirection {
  up,
  down,
  left,
  right,
}
