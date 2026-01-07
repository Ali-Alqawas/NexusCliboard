# NexusClip - نظام الحافظة الذكي
# Smart Clipboard Management System

<div align="center">

![NexusClip Logo](assets/icons/app_icon.png)

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-blue.svg)](https://flutter.dev)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.9-purple.svg)](https://kotlinlang.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%208.0%2B-brightgreen.svg)](https://android.com)

**تطبيق إدارة حافظة ثوري بمعمارية هجينة Flutter + Kotlin**

**Revolutionary clipboard management app with hybrid Flutter + Kotlin architecture**

</div>

---

## 🌟 المميزات / Features

### ✨ المقبض الجانبي الذكي / Smart Edge Handle
- مرسوم بـ Native XML (استهلاك منخفض للغاية)
- قابل للسحب عمودياً
- يعمل 24/7 باستهلاك 5-10MB فقط

### 📋 خزنة الحافظة / Clipboard Vault
- **Live Stream**: آخر 50 عنصر منسوخ
- **Code Snippets**: تصنيف تلقائي للأكواد مع تلوين Syntax
- **Secure Vault**: تشفير AES-256 لكلمات المرور
- **Templates**: قوالب نصية قابلة للتخصيص
- **Links**: إدارة الروابط مع معاينة

### 🎮 Virtual D-Pad
- تحكم بالمؤشر من أي تطبيق
- أزرار الأسهم (↑ ↓ ← →)
- Haptic Feedback

### 🔄 مزامنة Linux / Linux Sync
- مزامنة عبر الشبكة المحلية (LAN)
- بروتوكول UDP على Port 4040
- اكتشاف تلقائي للأجهزة

---

## 🏗️ المعمارية / Architecture

### المعمارية الهجينة الذكية / Smart Hybrid Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    NexusClip Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Native Kotlin Layer (الحارس الصامت)          │  │
│  │  ┌─────────────┐ ┌──────────────┐ ┌───────────────┐  │  │
│  │  │   Service   │ │ Accessibility│ │  Side Handle  │  │  │
│  │  │  24/7 Run   │ │   Service    │ │  (XML View)   │  │  │
│  │  └─────────────┘ └──────────────┘ └───────────────┘  │  │
│  │                    5-10MB RAM                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                 │
│                    Method Channels                          │
│                    Event Channels                           │
│                           │                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Flutter Layer (المارد النائم)                │  │
│  │  ┌─────────────┐ ┌──────────────┐ ┌───────────────┐  │  │
│  │  │   Vault     │ │   Database   │ │  Encryption   │  │  │
│  │  │     UI      │ │    (Hive)    │ │  (AES-256)    │  │  │
│  │  └─────────────┘ └──────────────┘ └───────────────┘  │  │
│  │              60-80MB RAM (عند الطلب فقط)             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 التثبيت / Installation

### المتطلبات / Requirements
- Android 8.0 (API 26) أو أعلى
- صلاحية العرض فوق التطبيقات
- صلاحية خدمة الوصول (اختياري)

### خطوات التثبيت / Installation Steps

1. **تحميل APK / Download APK**
   - [Release APK](releases/nexusclip-release.apk)
   - [Debug APK](releases/nexusclip-debug.apk)

2. **تثبيت التطبيق / Install App**
   ```bash
   adb install nexusclip-release.apk
   ```

3. **تفعيل الصلاحيات / Enable Permissions**
   - الإعدادات → التطبيقات → NexusClip → صلاحيات خاصة
   - تفعيل "العرض فوق التطبيقات"
   - الإعدادات → الوصول → NexusClip → تفعيل

---

## 🔧 البناء من المصدر / Build from Source

### المتطلبات / Prerequisites
```bash
Flutter 3.35.4+
Dart 3.9.2+
Android SDK 35
Kotlin 1.9+
```

### خطوات البناء / Build Steps

```bash
# استنساخ المستودع / Clone repository
git clone https://github.com/yourusername/nexusclip.git
cd nexusclip

# تثبيت الاعتمادات / Install dependencies
flutter pub get

# بناء Debug APK
flutter build apk --debug

# بناء Release APK
flutter build apk --release
```

---

## 🖥️ مزامنة Linux / Linux Sync

### تثبيت سكريبت Python / Install Python Script

```bash
# الانتقال لمجلد Linux Companion
cd linux_companion

# تثبيت الاعتمادات / Install dependencies
pip install pyperclip zeroconf

# تشغيل الـ Daemon
python3 nexusclip_daemon.py
```

### الاستخدام / Usage
```bash
# تشغيل عادي / Normal run
python3 nexusclip_daemon.py

# مع رسائل مفصلة / With verbose output
python3 nexusclip_daemon.py -v

# تحديد منفذ مخصص / Custom port
python3 nexusclip_daemon.py -p 4041
```

---

## 📂 هيكل المشروع / Project Structure

```
nexusclip/
├── android/
│   └── app/src/main/
│       ├── kotlin/com/nexusclip/clip/
│       │   ├── MainActivity.kt              # نقطة الدخول + Method Channels
│       │   ├── NexusClipService.kt          # الخدمة الأمامية + المقبض
│       │   ├── ClipboardAccessibilityService.kt  # خدمة الوصول
│       │   ├── OverlayActivity.kt           # نشاط Flutter العائم
│       │   └── BootReceiver.kt              # بدء تلقائي عند الإقلاع
│       └── res/
│           ├── values/
│           │   ├── strings.xml
│           │   ├── styles.xml
│           │   └── colors.xml
│           └── xml/
│               └── accessibility_service_config.xml
├── lib/
│   ├── main.dart                    # نقطة الدخول الرئيسية
│   ├── core/
│   │   ├── models/
│   │   │   └── clip_item.dart       # نموذج عنصر الحافظة
│   │   ├── services/
│   │   │   ├── database_service.dart    # خدمة قاعدة البيانات (Hive)
│   │   │   ├── platform_service.dart    # الجسر مع Native
│   │   │   ├── encryption_service.dart  # التشفير AES-256
│   │   │   └── sync_service.dart        # المزامنة مع Linux
│   │   └── theme/
│   │       ├── app_colors.dart      # نظام الألوان Cyber-Luxury
│   │       └── app_theme.dart       # ثيم التطبيق
│   └── features/
│       └── vault/
│           ├── presentation/
│           │   ├── vault_screen.dart    # شاشة الخزنة الرئيسية
│           │   └── setup_screen.dart    # شاشة الإعداد
│           └── widgets/
│               ├── clip_item_card.dart  # بطاقة العنصر
│               ├── virtual_dpad.dart    # لوحة الأسهم
│               └── glassmorphic_container.dart  # حاوية Glassmorphism
└── linux_companion/
    └── nexusclip_daemon.py          # سكريبت المزامنة مع Linux
```

---

## 🎨 نظام الألوان / Color System

### Cyber-Luxury Theme

| اللون / Color | الكود / Code | الاستخدام / Usage |
|---------------|--------------|-------------------|
| Deep Navy | `#001E28` | الخلفية الأساسية |
| Golden Bronze | `#B48C69` | العناصر التفاعلية |
| Soft Cream | `#E5CDAF` | النصوص الرئيسية |
| Electric Amber | `#FFB300` | التنبيهات |
| Cyan | `#00BCD4` | Live Stream |
| Green | `#8BC34A` | Code Snippets |
| Pink | `#E91E63` | Secure Vault |
| Purple | `#9C27B0` | Templates |
| Blue | `#2196F3` | Links |

---

## ⚡ الأداء / Performance

| المقياس / Metric | القيمة / Value |
|-----------------|----------------|
| RAM (خمول) | < 10MB |
| RAM (تشغيل) | < 80MB |
| CPU (خمول) | 0% |
| CPU (تشغيل) | < 5% |
| Battery/day | < 2% |
| Panel open time | < 100ms |
| Search time | < 50ms |
| APK size | < 30MB |

---

## 🔐 الأمان / Security

- **تشفير AES-256** للبيانات الحساسة
- **Flutter Secure Storage** لحفظ المفاتيح
- **مصادقة بيومترية** للخزنة الآمنة
- **لا يتم إرسال بيانات للإنترنت**
- **المزامنة محلية فقط (LAN)**

---

## 📝 API Documentation

### Method Channels

| Channel | Method | Description |
|---------|--------|-------------|
| `com.nexusclip.clip/methods` | `startService` | بدء الخدمة الأمامية |
| | `stopService` | إيقاف الخدمة |
| | `checkOverlayPermission` | التحقق من صلاحية العرض |
| | `requestOverlayPermission` | طلب صلاحية العرض |
| | `moveCursor` | تحريك المؤشر (up/down/left/right) |
| `com.nexusclip.clip/clipboard` | `getClipboardContent` | الحصول على محتوى الحافظة |
| | `setClipboardContent` | تعيين محتوى الحافظة |
| | `getClipboardHistory` | الحصول على السجل |

---

## 🐛 استكشاف الأخطاء / Troubleshooting

### المقبض لا يظهر / Handle not showing
1. تأكد من تفعيل صلاحية "العرض فوق التطبيقات"
2. أعد تشغيل التطبيق
3. تأكد من تشغيل الخدمة من الإعدادات

### الحافظة لا تُراقب / Clipboard not monitored
1. فعّل خدمة الوصول من الإعدادات
2. أعد تشغيل الجهاز بعد التفعيل

### المزامنة لا تعمل / Sync not working
1. تأكد من أن الجهازين على نفس الشبكة
2. تأكد من فتح Port 4040 في جدار الحماية
3. شغّل الـ Daemon بـ `-v` لعرض السجلات

---

## 📄 الترخيص / License

```
MIT License

Copyright (c) 2024 NexusClip

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🤝 المساهمة / Contributing

نرحب بالمساهمات! يرجى:

1. Fork المستودع
2. إنشاء فرع للميزة (`git checkout -b feature/amazing-feature`)
3. Commit التغييرات (`git commit -m 'Add amazing feature'`)
4. Push للفرع (`git push origin feature/amazing-feature`)
5. فتح Pull Request

---

## 📞 التواصل / Contact

- **GitHub Issues**: للإبلاغ عن الأخطاء والاقتراحات
- **Email**: support@nexusclip.app

---

<div align="center">

**صُنع بـ ❤️ باستخدام Flutter و Kotlin**

**Made with ❤️ using Flutter and Kotlin**

</div>
