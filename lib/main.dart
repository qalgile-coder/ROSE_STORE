import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    
    ThemeMode activeThemeMode = settings.themeMode;
    final user = userModel.valueOrNull;
    
    if (user != null && user.role != UserRole.customer) {
      activeThemeMode = ThemeMode.dark;
    }

    return MaterialApp.router(
      title: 'ROOZ Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: activeThemeMode,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}