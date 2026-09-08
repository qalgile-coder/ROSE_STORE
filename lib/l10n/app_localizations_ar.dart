// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcomeTitle => 'مرحباً بك في روز';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String get alreadyMember => 'لديك حساب بالفعل؟ ';

  @override
  String get premiumVendors => 'متاجر مميزة';

  @override
  String get expressDelivery => 'توصيل سريع';

  @override
  String get storeName => 'متجر روز';

  @override
  String get welcomeSubtitle => 'الجيل القادم من تجربة التسوق وإدارة المتاجر متعددة البائعين.';
}