import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// تم تعديل سطر الاستيراد هنا ليكون مباشراً من مجلد l10n المحلي
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'core/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';
import 'core/providers.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  try {
    await Firebase.initializeApp();
    await CacheService.initialize();
    NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const RoozStoreApp(),
    ),
  );
}

class RoozStoreApp extends ConsumerWidget {
  const RoozStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final userModel = ref.watch(userModelProvider);
    
    // جعل الوضع النهاري (Light) هو الافتراضي والطبيعي تماماً للتطبيق
    ThemeMode activeThemeMode = ThemeMode.light;
    
    // إذا كان هناك إعداد محفوظ مسبقاً، نتحقق منه، ولكن نجعل الوضع النهاري طابعاً افتراضياً أساسياً
    if (settings.themeMode == ThemeMode.dark || settings.themeMode == ThemeMode.system) {
      activeThemeMode = settings.themeMode;
    }

    final user = userModel.valueOrNull;
    
    // تخصيص الأدوار إن وجدت، مع الحفاظ على إمكانية فرض الوضع الليلي للمشرفين إذا رغبت، 
    // أو إبقاء الوضع النهاري هو السائد بناءً على طلبك.
    if (user != null && user.role != UserRole.customer) {
      // يمكنك تركها أو تخصيصها، هنا سنتركها تتجاوب مع الإعدادات الشخصية للمستخدم إن وجد
      // activeThemeMode = ThemeMode.dark; 
    }

    return MaterialApp.router(
      title: 'ROOZ Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: activeThemeMode, // تم جعله يفتح على الوضع النهاري كافتراضي أساسي
      // تثبيت اللغة العربية لتكون اللغة الأم والأساسية للتطبيق بالكامل
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate, // مندوب الترجمة الخاص بالتطبيق
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        // إجبار النظام دائماً على اعتماد العربية كافتراضي بغض النظر عن لغة الجهاز
        return const Locale('ar');
      },
      // إجبار كافة الشاشات والعناصر على اتجاه اليمين لليسار (RTL) للغة العربية
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}