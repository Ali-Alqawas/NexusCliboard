# NexusClip API Documentation
# توثيق واجهة برمجة التطبيقات (API)

## Overview / نظرة عامة

NexusClip uses a hybrid architecture with three main communication layers:
يستخدم NexusClip معمارية هجينة مع ثلاث طبقات اتصال رئيسية:

1. **Method Channels** - Flutter ↔ Kotlin communication / التواصل بين Flutter و Kotlin
2. **Event Channels** - Real-time event streaming / البث المباشر للأحداث
3. **UDP Protocol** - Android ↔ Linux sync / المزامنة بين Android و Linux

---

## Method Channels / قنوات الأوامر

### Channel Name / اسم القناة
```
com.nexusclip/main
```

### Methods / الأوامر

#### `startService`
Starts the NexusClip foreground service.
يبدأ خدمة NexusClip في الخلفية.

```dart
// Flutter
await platform.invokeMethod('startService');
```

```kotlin
// Kotlin Response
result.success(true)
```

---

#### `stopService`
Stops the NexusClip foreground service.
يوقف خدمة NexusClip.

```dart
// Flutter
await platform.invokeMethod('stopService');
```

---

#### `getServiceStatus`
Returns current service status.
يرجع حالة الخدمة الحالية.

```dart
// Flutter
final status = await platform.invokeMethod<Map>('getServiceStatus');
// Returns: { 'isRunning': true, 'clipboardCount': 42 }
```

---

#### `showOverlay`
Shows the side panel overlay.
يعرض لوحة الشريط الجانبي.

```dart
// Flutter
await platform.invokeMethod('showOverlay', {'type': 'sidebar'});
```

**Parameters / المعاملات:**
- `type`: `'sidebar'` | `'vault'` | `'dpad'`

---

#### `hideOverlay`
Hides all overlay windows.
يخفي جميع نوافذ الطبقة.

```dart
// Flutter
await platform.invokeMethod('hideOverlay');
```

---

#### `updateHandlePosition`
Updates the side handle position.
يحدث موضع المقبض الجانبي.

```dart
// Flutter
await platform.invokeMethod('updateHandlePosition', {
  'y': 0.5,  // 0.0 to 1.0 (percentage from top)
  'side': 'right'  // 'left' or 'right'
});
```

---

#### `sendKeyEvent`
Sends keyboard event for D-Pad navigation.
يرسل حدث لوحة المفاتيح للتنقل.

```dart
// Flutter
await platform.invokeMethod('sendKeyEvent', {
  'keyCode': 'DPAD_UP'  // DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT, DPAD_CENTER
});
```

**Supported Key Codes / أكواد المفاتيح المدعومة:**
- `DPAD_UP` - Move cursor up / تحريك المؤشر للأعلى
- `DPAD_DOWN` - Move cursor down / تحريك المؤشر للأسفل
- `DPAD_LEFT` - Move cursor left / تحريك المؤشر لليسار
- `DPAD_RIGHT` - Move cursor right / تحريك المؤشر لليمين
- `DPAD_CENTER` - Click/Confirm / النقر/التأكيد

---

#### `copyToClipboard`
Copies text to system clipboard.
ينسخ النص إلى حافظة النظام.

```dart
// Flutter
await platform.invokeMethod('copyToClipboard', {'text': 'Hello World'});
```

---

#### `getClipboardHistory`
Gets clipboard history (last N items).
يحصل على سجل الحافظة.

```dart
// Flutter
final history = await platform.invokeMethod<List>('getClipboardHistory', {
  'limit': 50
});
```

---

## Event Channels / قنوات الأحداث

### Channel Name / اسم القناة
```
com.nexusclip/events
```

### Events / الأحداث

#### `clipboard_changed`
Fired when clipboard content changes.
يُطلق عند تغيير محتوى الحافظة.

```dart
// Flutter Listener
eventChannel.receiveBroadcastStream().listen((event) {
  if (event['type'] == 'clipboard_changed') {
    final content = event['content'];
    final timestamp = event['timestamp'];
    print('New clipboard: $content');
  }
});
```

**Event Data / بيانات الحدث:**
```json
{
  "type": "clipboard_changed",
  "content": "Copied text",
  "contentType": "text",
  "timestamp": 1704567890123,
  "sourceApp": "com.example.app"
}
```

---

#### `service_status_changed`
Fired when service status changes.
يُطلق عند تغيير حالة الخدمة.

```json
{
  "type": "service_status_changed",
  "isRunning": true,
  "reason": "user_started"
}
```

---

#### `sync_event`
Fired for Linux sync events.
يُطلق لأحداث المزامنة مع Linux.

```json
{
  "type": "sync_event",
  "action": "received",
  "source": "192.168.1.100",
  "platform": "Linux"
}
```

---

## UDP Sync Protocol / بروتوكول المزامنة UDP

### Connection / الاتصال

**Port / المنفذ:** `4040`
**Transport:** UDP Broadcast / بث UDP

### Message Format / صيغة الرسائل

All messages are UTF-8 encoded strings.
جميع الرسائل مشفرة بـ UTF-8.

---

### Discovery / الاكتشاف

#### Discovery Request / طلب الاكتشاف
```
NEXUSCLIP_DISCOVER
```

#### Discovery Response / رد الاكتشاف
```
NEXUSCLIP_DEVICE:<platform>|<device_name>
```

**Example / مثال:**
```
NEXUSCLIP_DEVICE:Android|Samsung Galaxy S21
NEXUSCLIP_DEVICE:Linux|ubuntu-desktop
```

---

### Clipboard Sync / مزامنة الحافظة

#### Clipboard Message / رسالة الحافظة
```
NEXUSCLIP_CLIP:<base64_encoded_content>
```

**Example / مثال:**
```
NEXUSCLIP_CLIP:SGVsbG8gV29ybGQh
```

#### Acknowledgment / التأكيد
```
NEXUSCLIP_ACK:RECEIVED
```

---

### Heartbeat / نبضة القلب

Sent every 30 seconds to maintain connection.
تُرسل كل 30 ثانية للحفاظ على الاتصال.

```
NEXUSCLIP_HEARTBEAT
```

---

## Data Models / نماذج البيانات

### ClipItem / عنصر الحافظة

```dart
class ClipItem {
  final String id;           // Unique identifier / معرف فريد
  final String content;      // Clipboard content / محتوى الحافظة
  final ClipType type;       // Content type / نوع المحتوى
  final DateTime createdAt;  // Creation timestamp / وقت الإنشاء
  final String? sourceApp;   // Source application / التطبيق المصدر
  final bool isPinned;       // Is pinned / مثبت
  final bool isEncrypted;    // Is encrypted / مشفر
  final int usageCount;      // Usage count / عدد الاستخدام
}
```

### ClipType / نوع المحتوى

```dart
enum ClipType {
  text,        // Plain text / نص عادي
  link,        // URL/Link / رابط
  code,        // Code snippet / مقطع كود
  password,    // Sensitive data / بيانات حساسة
  email,       // Email address / بريد إلكتروني
  phone,       // Phone number / رقم هاتف
  template,    // Template/Quick reply / قالب/رد سريع
}
```

---

## Security / الأمان

### Encryption / التشفير

Secure Vault items use AES-256 encryption:
عناصر الخزنة الآمنة تستخدم تشفير AES-256:

```dart
// Encryption (simplified)
final key = await EncryptionService.deriveKey(userPassword);
final encrypted = EncryptionService.encrypt(plaintext, key);

// Decryption
final decrypted = EncryptionService.decrypt(encrypted, key);
```

### Biometric Authentication / المصادقة البيومترية

```dart
// Check availability
final canAuthenticate = await LocalAuth.canCheckBiometrics;

// Authenticate
final authenticated = await LocalAuth.authenticate(
  localizedReason: 'Access Secure Vault',
  options: AuthenticationOptions(biometricOnly: true),
);
```

---

## Error Codes / رموز الأخطاء

| Code | Description (EN) | Description (AR) |
|------|-----------------|------------------|
| `E001` | Service not running | الخدمة غير مشغلة |
| `E002` | Permission denied | الإذن مرفوض |
| `E003` | Overlay permission required | إذن الطبقة مطلوب |
| `E004` | Accessibility not enabled | إمكانية الوصول غير مفعلة |
| `E005` | Encryption failed | فشل التشفير |
| `E006` | Authentication failed | فشل المصادقة |
| `E007` | Sync connection lost | فقد اتصال المزامنة |
| `E008` | Database error | خطأ في قاعدة البيانات |

---

## Performance Metrics / مقاييس الأداء

| Metric | Target | Actual |
|--------|--------|--------|
| Service RAM (idle) | < 10 MB | ~5-8 MB |
| Flutter RAM (active) | < 80 MB | ~60-70 MB |
| Service CPU (idle) | 0% | ~0% |
| Battery drain (24h) | < 2% | ~1.5% |
| Overlay open time | < 100ms | ~80ms |
| Method Channel latency | < 5ms | ~2-3ms |
| Sync latency (LAN) | < 50ms | ~20-30ms |

---

## Example Implementation / مثال التنفيذ

### Complete Clipboard Copy Flow / تدفق النسخ الكامل

```dart
import 'package:flutter/services.dart';

class ClipboardManager {
  static const platform = MethodChannel('com.nexusclip/main');
  static const events = EventChannel('com.nexusclip/events');
  
  // Copy to clipboard
  Future<void> copyText(String text) async {
    try {
      // 1. Copy to system clipboard
      await platform.invokeMethod('copyToClipboard', {'text': text});
      
      // 2. Native service will detect and save to history
      // 3. Sync will broadcast to connected devices
      
      print('Text copied successfully');
    } on PlatformException catch (e) {
      print('Failed to copy: ${e.message}');
    }
  }
  
  // Listen for clipboard changes
  void startListening() {
    events.receiveBroadcastStream().listen(
      (event) {
        if (event['type'] == 'clipboard_changed') {
          _handleClipboardChange(event);
        }
      },
      onError: (error) {
        print('Event stream error: $error');
      },
    );
  }
  
  void _handleClipboardChange(Map<dynamic, dynamic> event) {
    final content = event['content'] as String;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      event['timestamp'] as int
    );
    
    print('Clipboard changed at $timestamp: $content');
  }
}
```

---

## Version History / سجل الإصدارات

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-01 | Initial release / الإصدار الأولي |

---

## Support / الدعم

- GitHub: [NexusCliboard](https://github.com/Ali-Alqawas/NexusCliboard)
- Issues: Report bugs via GitHub Issues
- Email: support@nexusclip.app

---

*NexusClip - Smart Clipboard Management System*
*نظام إدارة الحافظة الذكية*
