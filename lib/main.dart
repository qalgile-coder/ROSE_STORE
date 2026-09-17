import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- تأكد من استيراد حزمة المراسلة
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'core/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';
import 'core/providers.dart';
import 'models/user_model.dart';

// 1. دالة معالجة الإشعارات في الخلفية (يجب أن تكون خارج أي كلاس Top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  try {
    await Firebase.initializeApp();
    
    // 2. تسجيل معالج الخلفية الخاص بـ Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await CacheService.initialize();
    
    // 3. إضافة await لضمان تهيئة خدمة الإشعارات بشكل صحيح وسليم
    await NotificationService().initialize();
    
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
    
    ThemeMode activeThemeMode = ThemeMode.light;
    
    if (settings.themeMode == ThemeMode.dark || settings.themeMode == ThemeMode.system) {
      activeThemeMode = settings.themeMode;
    }

    return MaterialApp.router(
      title: 'ROOZ Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: activeThemeMode,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        return const Locale('ar');
      },
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
