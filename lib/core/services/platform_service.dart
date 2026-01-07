import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' show Platform;

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

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // بث الأحداث / Event stream
  Stream<dynamic>? _eventStream;
  StreamSubscription<dynamic>? _eventSubscription;

  // التحقق من منصة Android
  bool get _isAndroid {
    try {
      return !kIsWeb && Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // التهيئة / Initialization
  // =====================================================

  /// تهيئة الخدمة
  /// Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // التحقق من المنصة - الخدمة متاحة فقط على Android
    if (!_isAndroid) {
      if (kDebugMode) {
        debugPrint('PlatformService: Not running on Android, skipping initialization');
      }
      _isInitialized = true;
      return;
    }

    try {
      // التحقق من الصلاحيات
      await checkAllPermissions();

      // الاستماع للأحداث
      try {
        _eventStream = _eventChannel.receiveBroadcastStream();
        _eventSubscription = _eventStream?.listen(
          _handleEvent,
          onError: (error) {
            if (kDebugMode) {
              debugPrint('Event stream error: $error');
            }
          },
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error setting up event stream: $e');
        }
      }

      // محاولة بدء الخدمة إذا كانت الصلاحيات موجودة
      if (_hasOverlayPermission) {
        await startService();
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing platform service: $e');
      }
      _isInitialized = true; // نعتبرها مهيأة حتى مع الخطأ
    }
  }

  /// التخلص من الموارد
  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _eventStream = null;
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
    if (kDebugMode) {
      debugPrint('Clipboard changed: ${event['content']}');
    }
  }

  void _handleHandleTap(Map<String, dynamic> event) {
    // يمكن إضافة معالجة إضافية هنا
    // Additional handling can be added here
    if (kDebugMode) {
      debugPrint('Handle tapped');
    }
  }

  // =====================================================
  // إدارة الخدمة / Service Management
  // =====================================================

  /// بدء الخدمة الأمامية
  /// Start foreground service
  Future<bool> startService() async {
    if (!_isAndroid) {
      if (kDebugMode) {
        debugPrint('startService: Not available on this platform');
      }
      return false;
    }

    try {
      final result = await _methodChannel.invokeMethod<bool>('startService');
      _isServiceRunning = result ?? false;
      return _isServiceRunning;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting service: ${e.message}');
      }
      return false;
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint('startService: Plugin not available');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error starting service: $e');
      }
      return false;
    }
  }

  /// إيقاف الخدمة
  /// Stop service
  Future<bool> stopService() async {
    if (!_isAndroid) {
      return false;
    }

    try {
      final result = await _methodChannel.invokeMethod<bool>('stopService');
      _isServiceRunning = !(result ?? true);
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error stopping service: ${e.message}');
      }
      return false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error stopping service: $e');
      }
      return false;
    }
  }

  /// التحقق من حالة الخدمة
  /// Check service status
  Future<bool> checkServiceStatus() async {
    if (!_isAndroid) {
      return false;
    }

    try {
      final result = await _methodChannel.invokeMethod<bool>('isServiceRunning');
      _isServiceRunning = result ?? false;
      return _isServiceRunning;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking service status: ${e.message}');
      }
      return false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error checking service status: $e');
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
    if (!_isAndroid) {
      // على المنصات غير Android، نعتبر الصلاحيات موجودة
      return {'overlay': true, 'accessibility': true};
    }

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
    } on MissingPluginException {
      // على المحاكي أو بدون native implementation
      return {'overlay': true, 'accessibility': true};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error checking permissions: $e');
      }
      return {'overlay': false, 'accessibility': false};
    }
  }

  /// التحقق من صلاحية العرض فوق التطبيقات
  /// Check overlay permission
  Future<bool> checkOverlayPermission() async {
    if (!_isAndroid) {
      return true;
    }

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
    } on MissingPluginException {
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error checking overlay permission: $e');
      }
      return false;
    }
  }

  /// طلب صلاحية العرض فوق التطبيقات
  /// Request overlay permission
  Future<void> requestOverlayPermission() async {
    if (!_isAndroid) {
      return;
    }

    try {
      await _methodChannel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting overlay permission: ${e.message}');
      }
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint('requestOverlayPermission: Plugin not available');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error requesting overlay permission: $e');
      }
    }
  }

  /// التحقق من صلاحية خدمة الوصول
  /// Check accessibility permission
  Future<bool> checkAccessibilityPermission() async {
    if (!_isAndroid) {
      return true;
    }

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
    } on MissingPluginException {
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error checking accessibility permission: $e');
      }
      return false;
    }
  }

  /// طلب صلاحية خدمة الوصول
  /// Request accessibility permission
  Future<void> requestAccessibilityPermission() async {
    if (!_isAndroid) {
      return;
    }

    try {
      await _methodChannel.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting accessibility permission: ${e.message}');
      }
    } on MissingPluginException {
      if (kDebugMode) {
        debugPrint('requestAccessibilityPermission: Plugin not available');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error requesting accessibility permission: $e');
      }
    }
  }

  // =====================================================
  // التحكم بالمؤشر / Cursor Control
  // =====================================================

  /// تحريك المؤشر
  /// Move cursor
  Future<bool> moveCursor(CursorDirection direction) async {
    if (!_isAndroid) {
      if (kDebugMode) {
        debugPrint('moveCursor: Not available on this platform');
      }
      return false;
    }

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
    } on MissingPluginException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error moving cursor: $e');
      }
      return false;
    }
  }

  /// إرسال حدث زر
  /// Send key event
  Future<bool> sendKeyEvent(int keyCode) async {
    if (!_isAndroid) {
      return false;
    }

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
    } on MissingPluginException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error sending key event: $e');
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
    if (!_isAndroid) {
      return false;
    }

    try {
      final result = await _methodChannel.invokeMethod<bool>('showHandle');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing handle: ${e.message}');
      }
      return false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error showing handle: $e');
      }
      return false;
    }
  }

  /// إخفاء المقبض
  /// Hide handle
  Future<bool> hideHandle() async {
    if (!_isAndroid) {
      return false;
    }

    try {
      final result = await _methodChannel.invokeMethod<bool>('hideHandle');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error hiding handle: ${e.message}');
      }
      return false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error hiding handle: $e');
      }
      return false;
    }
  }

  /// تعيين موضع المقبض
  /// Set handle position
  Future<bool> setHandlePosition(double y) async {
    if (!_isAndroid) {
      return false;
    }

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
    } on MissingPluginException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error setting handle position: $e');
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
      // استخدام Flutter Clipboard API بدلاً من native إذا لم نكن على Android
      if (!_isAndroid) {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return data?.text;
      }

      final result = await _clipboardChannel.invokeMethod<String>(
        'getClipboardContent',
      );
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting clipboard content: ${e.message}');
      }
      // Fallback to Flutter API
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return data?.text;
      } catch (_) {
        return null;
      }
    } on MissingPluginException {
      // Fallback to Flutter API
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        return data?.text;
      } catch (_) {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error getting clipboard content: $e');
      }
      return null;
    }
  }

  /// تعيين محتوى الحافظة
  /// Set clipboard content
  Future<bool> setClipboardContent(String text) async {
    try {
      // استخدام Flutter Clipboard API بدلاً من native إذا لم نكن على Android
      if (!_isAndroid) {
        await Clipboard.setData(ClipboardData(text: text));
        return true;
      }

      final result = await _clipboardChannel.invokeMethod<bool>(
        'setClipboardContent',
        {'text': text},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting clipboard content: ${e.message}');
      }
      // Fallback to Flutter API
      try {
        await Clipboard.setData(ClipboardData(text: text));
        return true;
      } catch (_) {
        return false;
      }
    } on MissingPluginException {
      // Fallback to Flutter API
      try {
        await Clipboard.setData(ClipboardData(text: text));
        return true;
      } catch (_) {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error setting clipboard content: $e');
      }
      return false;
    }
  }

  /// الحصول على سجل الحافظة
  /// Get clipboard history
  Future<List<Map<String, dynamic>>> getClipboardHistory() async {
    if (!_isAndroid) {
      return [];
    }

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
    } on MissingPluginException {
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error getting clipboard history: $e');
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
    if (!_isAndroid) {
      return {
        'platform': kIsWeb ? 'web' : 'unknown',
        'isEmulator': false,
      };
    }

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
    } on MissingPluginException {
      return {'platform': 'android', 'pluginMissing': true};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error getting device info: $e');
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
