import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/platform_service.dart';
import 'core/services/encryption_service.dart';
import 'core/services/sync_service.dart';
import 'features/vault/presentation/vault_screen.dart';
import 'features/vault/presentation/setup_screen.dart';

/// NexusClip - نقطة الدخول الرئيسية
/// Main Entry Point
///
/// هذا هو التطبيق الرئيسي الذي يُفتح من أيقونة التطبيق
/// This is the main app opened from the app icon
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الخدمات / Initialize services
  await _initializeServices();

  // تعيين وضع الشاشة / Set screen orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // تعيين ألوان شريط النظام / Set system bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF001E28),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const NexusClipApp());
}

/// نقطة دخول الـ Overlay (يُستدعى من OverlayActivity)
/// Overlay Entry Point (called from OverlayActivity)
@pragma('vm:entry-point')
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _initializeServices();
  
  runApp(const NexusClipOverlay());
}

/// تهيئة جميع الخدمات
/// Initialize all services
Future<void> _initializeServices() async {
  // قاعدة البيانات / Database
  await DatabaseService().initialize();

  // التشفير / Encryption
  await EncryptionService().initialize();

  // خدمة المنصة / Platform service
  await PlatformService().initialize();
}

/// تطبيق NexusClip الرئيسي
/// Main NexusClip Application
class NexusClipApp extends StatelessWidget {
  const NexusClipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: DatabaseService()),
        Provider<PlatformService>.value(value: PlatformService()),
        Provider<EncryptionService>.value(value: EncryptionService()),
        Provider<SyncService>.value(value: SyncService()),
      ],
      child: MaterialApp(
        title: 'NexusClip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}

/// تطبيق الـ Overlay
/// Overlay Application
class NexusClipOverlay extends StatelessWidget {
  const NexusClipOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: DatabaseService()),
        Provider<PlatformService>.value(value: PlatformService()),
        Provider<EncryptionService>.value(value: EncryptionService()),
      ],
      child: MaterialApp(
        title: 'NexusClip Overlay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const VaultScreen(isOverlay: true),
      ),
    );
  }
}

/// الشاشة الرئيسية
/// Main Screen
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoading = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final platformService = PlatformService();
    final permissions = await platformService.checkAllPermissions();
    
    setState(() {
      _hasPermissions = permissions['overlay'] == true;
      _isLoading = false;
    });

    // بدء الخدمة إذا كانت الصلاحيات موجودة
    if (_hasPermissions) {
      await platformService.startService();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // إذا لم تكن الصلاحيات موجودة، اعرض شاشة الإعداد
    if (!_hasPermissions) {
      return SetupScreen(
        onSetupComplete: () {
          setState(() {
            _hasPermissions = true;
          });
        },
      );
    }

    // الصلاحيات موجودة - اعرض الخزنة
    return const VaultScreen(isOverlay: false);
  }
}
