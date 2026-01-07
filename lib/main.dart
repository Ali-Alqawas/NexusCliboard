import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
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

  // معالجة الأخطاء العامة
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // معالجة أخطاء المنطقة غير المتزامنة
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Async Error: $error');
      debugPrint('Stack: $stack');
    }
    return true;
  };

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
  runApp(const NexusClipOverlay());
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
        home: const AppInitializer(),
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
        home: const OverlayInitializer(),
      ),
    );
  }
}

/// مهيئ التطبيق - يدير تحميل الخدمات
/// App Initializer - manages service loading
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  String _loadingMessage = 'جاري تحميل التطبيق...';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. تهيئة قاعدة البيانات
      setState(() => _loadingMessage = 'جاري تهيئة قاعدة البيانات...');
      await _initializeDatabase();
      
      // 2. تهيئة خدمة التشفير
      setState(() => _loadingMessage = 'جاري تهيئة خدمة التشفير...');
      await _initializeEncryption();
      
      // 3. تهيئة خدمة المنصة
      setState(() => _loadingMessage = 'جاري التحقق من الصلاحيات...');
      await _initializePlatform();

      // انتهى التحميل بنجاح
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Initialization error: $e');
        debugPrint('Stack: $stack');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'حدث خطأ أثناء تحميل التطبيق:\n$e';
        });
      }
    }
  }

  Future<void> _initializeDatabase() async {
    try {
      await DatabaseService().initialize();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Database initialization error: $e');
      }
      // لا نرمي الخطأ - نسمح للتطبيق بالمتابعة
    }
  }

  Future<void> _initializeEncryption() async {
    try {
      await EncryptionService().initialize();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Encryption initialization error: $e');
      }
      // لا نرمي الخطأ - نسمح للتطبيق بالمتابعة
    }
  }

  Future<void> _initializePlatform() async {
    try {
      await PlatformService().initialize();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Platform initialization error: $e');
      }
      // لا نرمي الخطأ - هذا متوقع على منصات غير Android
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSplashScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    return const MainScreen();
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار التطبيق
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.content_paste_rounded,
                  size: 60,
                  color: AppColors.background,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // اسم التطبيق
              const Text(
                'NexusClip',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'نظام الحافظة الذكي',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // مؤشر التحميل
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // رسالة التحميل
              Text(
                _loadingMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة الخطأ
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 50,
                  color: AppColors.error,
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'حدث خطأ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // زر إعادة المحاولة
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializeApp();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // زر المتابعة على أي حال
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = false;
                    _error = null;
                  });
                },
                child: Text(
                  'المتابعة على أي حال',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مهيئ الـ Overlay
/// Overlay Initializer
class OverlayInitializer extends StatefulWidget {
  const OverlayInitializer({super.key});

  @override
  State<OverlayInitializer> createState() => _OverlayInitializerState();
}

class _OverlayInitializerState extends State<OverlayInitializer> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await DatabaseService().initialize();
      await EncryptionService().initialize();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Overlay initialization error: $e');
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return const VaultScreen(isOverlay: true);
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
    try {
      final platformService = PlatformService();
      final permissions = await platformService.checkAllPermissions();
      
      if (mounted) {
        setState(() {
          _hasPermissions = permissions['overlay'] == true;
          _isLoading = false;
        });
      }

      // بدء الخدمة إذا كانت الصلاحيات موجودة
      if (_hasPermissions) {
        await platformService.startService();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking permissions: $e');
      }
      
      if (mounted) {
        setState(() {
          _hasPermissions = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'جاري التحقق من الصلاحيات...',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
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
