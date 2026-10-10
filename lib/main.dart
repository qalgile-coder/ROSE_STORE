import 'dart:io';
import 'package:flutter/foundation.dart'; // تمت إضافة هذه المكتبة للتحقق من منصة الويب أو الهاتف
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // استيراد إعدادات فايربيز المعيارية لضمان عمل الويب بدون أخطاء
import 'package:firebase_messaging/firebase_messaging.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  try {
    // تمرير خيارات المنصة لضمان عدم ظهور خطأ [core/no-app] على الويب أو غيره
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 2. تسجيل معالج الخلفية الخاص بـ Firebase Messaging (يتم تجاوزه أوتوماتيكياً على الويب إذا لم يكن مدعوماً بنفس الطريقة)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // **الإضافة الاحترافية لحل المشكلة:** طلب صلاحيات الإشعارات صراحةً من النظام
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('Notification Permission Status: ${settings.authorizationStatus}');
    }

    await CacheService.initialize();
    
    // 3. تهيئة خدمة الإشعارات بشكل صحيح وسليم
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
    
    // التعديل الجذري الاحترافي: قراءة وضع الثيم مباشرة من الإعدادات ليدعم الوضع الفاتح والداكن والنظام بسلاسة
    final activeThemeMode = settings.themeMode;

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