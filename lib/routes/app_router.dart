import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🌐 استيراد حزم الترجمة والملفات والشاشات الخاصة بالمشروع
// (تأكد من تعديل مسارات الاستيراد بحسب هيكل مشروعك الفعلي)
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/developer/presentation/screens/developer_profile_screen.dart';

// الشاشات الخاصة باللوحات المختلفة
import '../features/admin/presentation/screens/admin_dashboard.dart';
import '../features/admin/presentation/screens/add_vendor_screen.dart';
import '../features/admin/presentation/screens/add_rider_screen.dart';
import '../features/admin/presentation/screens/notifications_screen.dart';
import '../features/admin/presentation/screens/admin_profile_screen.dart';
import '../features/admin/presentation/screens/analytics_dashboard_screen.dart';
import '../features/admin/presentation/screens/all_shops_screen.dart';
import '../features/admin/presentation/screens/shop_management_screen.dart';
import '../features/admin/presentation/screens/category_management_screen.dart';
import '../features/admin/presentation/screens/coupon_management_screen.dart' as admin;
import '../features/admin/presentation/screens/user_management_screen.dart';
import '../features/admin/presentation/screens/rider_management_screen.dart';
import '../features/admin/presentation/screens/pending_orders_screen.dart';
import '../features/admin/presentation/screens/customer_management_screen.dart';
import '../features/admin/presentation/screens/vendor_management_screen.dart';
import '../features/admin/presentation/screens/approval_center_screen.dart';
import '../features/admin/presentation/screens/payout_management_screen.dart';
import '../features/admin/presentation/screens/system_settings_screen.dart';
import '../features/admin/presentation/screens/system_info_screen.dart';
import '../features/admin/presentation/screens/activity_log_screen.dart';
import '../features/admin/presentation/screens/order_management_screen.dart';
import '../features/admin/presentation/screens/order_map_screen.dart';
import '../features/admin/presentation/screens/user_history_screen.dart';
import '../features/admin/presentation/screens/support_list_screen.dart';
import '../features/admin/presentation/screens/support_chat_detail_screen.dart';

// شاشات البائع (Vendor)
import '../features/vendor/presentation/screens/vendor_dashboard.dart';
import '../features/vendor/presentation/screens/add_product_screen.dart';
import '../features/vendor/presentation/screens/vendor_notifications_screen.dart';
import '../features/vendor/presentation/screens/vendor_profile_screen.dart';
import '../features/vendor/presentation/screens/edit_shop_screen.dart';
import '../features/vendor/presentation/screens/vendor_sales_analytics_screen.dart';
import '../features/vendor/presentation/screens/vendor_orders_screen.dart';
import '../features/vendor/presentation/screens/vendor_order_details_screen.dart';
import '../features/vendor/presentation/screens/product_management_screen.dart';
import '../features/vendor/presentation/screens/low_stock_screen.dart';
import '../features/vendor/presentation/screens/vendor_reviews_screen.dart';
import '../features/vendor/presentation/screens/coupon_management_screen.dart';
import '../features/vendor/presentation/screens/vendor_earnings_screen.dart';

// شاشات العميل (Customer)
import '../features/customer/presentation/screens/customer_home.dart';
import '../features/customer/presentation/screens/customer_profile_screen.dart';
import '../features/customer/presentation/screens/address_management_screen.dart';
import '../features/customer/presentation/screens/customer_search_screen.dart';
import '../features/customer/presentation/screens/wishlist_screen.dart';
import '../features/customer/presentation/screens/cart_screen.dart';
import '../features/customer/presentation/screens/checkout_screen.dart';
import '../features/customer/presentation/screens/customer_orders_screen.dart';
import '../features/customer/presentation/screens/customer_order_details_screen.dart';
import '../features/customer/presentation/screens/order_success_screen.dart';
import '../features/customer/presentation/screens/featured_shops_screen.dart';
import '../features/customer/presentation/screens/nearby_shops_screen.dart';
import '../features/customer/presentation/screens/trending_products_screen.dart';
import '../features/customer/presentation/screens/customer_all_products_screen.dart';
import '../features/customer/presentation/screens/category_shops_screen.dart';
import '../features/customer/presentation/screens/offer_details_screen.dart';
import '../features/customer/presentation/screens/product_details_screen.dart';
import '../features/customer/presentation/screens/product_reviews_screen.dart';
import '../features/customer/presentation/screens/shop_detail_screen.dart';
import '../features/customer/presentation/screens/customer_notifications_screen.dart';

// شاشات المندوب (Rider)
import '../features/rider/presentation/screens/rider_dashboard.dart';
import '../features/rider/presentation/screens/order_details_screen.dart';
import '../features/rider/presentation/screens/active_tasks_screen.dart';
import '../features/rider/presentation/screens/performance_details_screen.dart';
import '../features/rider/presentation/screens/rider_reviews_screen.dart';
import '../features/rider/presentation/screens/rider_profile_screen.dart';
import '../features/rider/presentation/screens/rider_history_screen.dart';
import '../features/rider/presentation/screens/rider_earnings_screen.dart';
import '../features/rider/presentation/screens/vehicle_details_screen.dart';
import '../features/rider/presentation/screens/support_center_screen.dart';
import '../features/rider/presentation/screens/support_chat_screen.dart';
import '../features/rider/presentation/screens/alerts_screen.dart';
import '../features/rider/presentation/screens/documents_screen.dart';

// شاشات الدعم والمحادثات العامة (Support & Chat)
import '../features/support/presentation/screens/support_hub_screen.dart';
import '../features/support/presentation/screens/create_ticket_screen.dart';
import '../features/support/presentation/screens/ticket_chat_screen.dart';
import '../features/support/presentation/screens/live_chat_screen.dart';
import '../features/support/presentation/screens/emergency_report_screen.dart';
import '../features/support/presentation/screens/emergency_details_screen.dart';
import '../features/support/presentation/screens/my_tickets_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';

// النماذج والـ Providers المطلوبة
import '../core/enums/user_role.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/user/providers/user_model_provider.dart';
import '../core/providers/splash_duration_provider.dart';
import '../core/providers/system_settings_provider.dart';
import '../features/customer/data/models/offer_model.dart';
import '../features/customer/data/models/product_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userModel = ref.read(userModelProvider);
      final splashWait = ref.read(splashDurationProvider);
      final settings = ref.read(systemSettingsProvider).valueOrNull;

      final currentPath = state.matchedLocation;

      final loggingIn = currentPath == '/login' ||
          currentPath == '/welcome' ||
          currentPath == '/signup' ||
          currentPath == '/verify-email';

      // فحص وضع الصيانة أولاً
      if (settings?.maintenanceMode == true) {
        final isSuperAdmin = userModel.valueOrNull?.role == UserRole.superAdmin;
        if (!isSuperAdmin) {
          return currentPath == '/maintenance' ? null : '/maintenance';
        }
      }

      if (splashWait.isLoading) return null;
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;

      // إذا لم يكن المستخدم مسجلاً دخولاً
      if (user == null) {
        return loggingIn ? null : '/welcome';
      }

      // 🛡️ [تعديل احترافي دقيق ومتزامن]: الاعتماد على كائن الـ user القادم من الـ authState مباشرة لتجنب أي تأخير في المزامنة
      final bool isEmailVerified = user.emailVerified;

      if (!isEmailVerified) {
        if (currentPath == '/verify-email' || currentPath == '/login' || currentPath == '/signup' || currentPath == '/welcome') {
          return null; // السماح بالرجوع والتنقل بحرية تامة دون إجبار قسري
        }
      }

      if (userModel.isLoading) return null;

      final model = userModel.valueOrNull;

      if (userModel.hasError || model == null) {
        if (loggingIn || currentPath == '/') return null;
        if (userModel.hasError && userModel.error is! Exception) return null;
        return '/welcome';
      }

      final isPublicScreen = loggingIn || currentPath == '/' || currentPath == '/welcome';

      if (isPublicScreen) {
        // إذا كان البريد غير مؤكد، امنع إعادة التوجيه التلقائي للوحة التحكم وأبقِ المستخدم في صفحة التحقق أو صفحات المصادقة
        if (!isEmailVerified) {
          return null;
        }

        String target = '/welcome';
        switch (model.role) {
          case UserRole.superAdmin:
            target = '/admin';
            break;
          case UserRole.vendor:
            target = '/vendor';
            break;
          case UserRole.customer:
            target = '/customer';
            break;
          case UserRole.rider:
            target = '/rider';
            break;
          default:
            target = '/welcome';
        }

        if (currentPath != target) {
          return target;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/developer-profile', builder: (context, state) => const DeveloperProfileScreen()),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings_suggest_rounded, size: 80, color: Color(0xFFC9A27E)),
                const SizedBox(height: 24),
                const Text('ROOZ Store', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    AppLocalizations.of(context)?.welcomeTitle ?? 'We are currently performing scheduled maintenance to improve your experience. Please check back shortly.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = (state.extra as String?) ?? FirebaseAuth.instance.currentUser?.email ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboard()),
      GoRoute(path: '/admin/add-vendor', builder: (context, state) => const AddVendorScreen()),
      GoRoute(path: '/admin/add-rider', builder: (context, state) => const AddRiderScreen()),
      GoRoute(path: '/admin/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/admin/profile', builder: (context, state) => const AdminProfileScreen()),
      GoRoute(path: '/admin/analytics', builder: (context, state) => const AnalyticsDashboardScreen()),
      GoRoute(path: '/admin/all-shops', builder: (context, state) => const AllShopsScreen()),
      GoRoute(path: '/admin/shops', builder: (context, state) => const ShopManagementScreen()),
      GoRoute(path: '/admin/categories', builder: (context, state) => const CategoryManagementScreen()),
      GoRoute(path: '/admin/coupons', builder: (context, state) => const admin.CouponManagementScreen()),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => UserManagementScreen(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/admin/riders',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Rider Management', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
          body: const RiderManagementScreen(),
        ),
      ),
      GoRoute(path: '/admin/pending-orders', builder: (context, state) => const PendingOrdersScreen()),
      GoRoute(
        path: '/admin/customers',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Customer Management', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
          body: const CustomerManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/vendors',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Vendor Management', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
          body: const VendorManagementScreen(),
        ),
      ),
      GoRoute(path: '/admin/approvals', builder: (context, state) => const ApprovalCenterScreen()),
      GoRoute(path: '/admin/payouts', builder: (context, state) => const PayoutManagementScreen()),
      GoRoute(path: '/admin/system', builder: (context, state) => const SystemSettingsScreen()),
      GoRoute(path: '/admin/system-info', builder: (context, state) => const SystemInfoScreen()),
      GoRoute(path: '/admin/activity-log', builder: (context, state) => const ActivityLogScreen()),
      GoRoute(path: '/admin/orders', builder: (context, state) => const OrderManagementScreen()),
      GoRoute(path: '/admin/order-map', builder: (context, state) => const OrderMapScreen()),
      GoRoute(
        path: '/admin/user-history/:userId/:role',
        builder: (context, state) => UserHistoryScreen(
          userId: state.pathParameters['userId']!,
          role: UserRole.values.firstWhere(
            (e) => e.name == state.pathParameters['role'],
            orElse: () => UserRole.unknown,
          ),
        ),
      ),
      GoRoute(path: '/admin/support', builder: (context, state) => const SupportListScreen()),
      GoRoute(
        path: '/admin/support-chat/:userId/:userName',
        builder: (context, state) => SupportChatDetailScreen(
          userId: state.pathParameters['userId']!,
          userName: state.pathParameters['userName']!,
        ),
      ),
      GoRoute(path: '/vendor', builder: (context, state) => const VendorDashboard()),
      GoRoute(path: '/vendor/add-product', builder: (context, state) => const AddProductScreen()),
      GoRoute(path: '/vendor/notifications', builder: (context, state) => const VendorNotificationsScreen()),
      GoRoute(path: '/vendor/profile', builder: (context, state) => const VendorProfileScreen()),
      GoRoute(path: '/vendor/edit-shop', builder: (context, state) => const EditShopScreen()),
      GoRoute(path: '/vendor/analytics', builder: (context, state) => const VendorSalesAnalyticsScreen()),
      GoRoute(path: '/vendor/orders', builder: (context, state) => const VendorOrdersScreen()),
      GoRoute(
        path: '/vendor/order-details/:id',
        builder: (context, state) => VendorOrderDetailsScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/vendor/products', builder: (context, state) => const ProductManagementScreen()),
      GoRoute(path: '/vendor/low-stock', builder: (context, state) => const LowStockScreen()),
      GoRoute(path: '/vendor/reviews', builder: (context, state) => const VendorReviewsScreen()),
      GoRoute(path: '/vendor/coupons', builder: (context, state) => const CouponManagementScreen()),
      GoRoute(path: '/vendor/earnings', builder: (context, state) => const VendorEarningsScreen()),
      GoRoute(path: '/customer', builder: (context, state) => const CustomerHome()),
      GoRoute(path: '/customer/profile', builder: (context, state) => const CustomerProfileScreen()),
      GoRoute(path: '/customer/addresses', builder: (context, state) => const AddressManagementScreen()),
      GoRoute(path: '/customer/search', builder: (context, state) => const CustomerSearchScreen()),
      GoRoute(path: '/customer/wishlist', builder: (context, state) => const WishlistScreen()),
      GoRoute(path: '/customer/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/customer/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/customer/orders', builder: (context, state) => const CustomerOrdersScreen()),
      GoRoute(
        path: '/customer/order-details/:id',
        builder: (context, state) => CustomerOrderDetailsScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/customer/order-success/:id',
        builder: (context, state) => OrderSuccessScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/customer/featured-shops', builder: (context, state) => const FeaturedShopsScreen()),
      GoRoute(path: '/customer/nearby-shops', builder: (context, state) => const NearbyShopsScreen()),
      GoRoute(path: '/customer/trending-products', builder: (context, state) => const TrendingProductsScreen()),
      GoRoute(
        path: '/customer/all-products',
        builder: (context, state) => const CustomerAllProductsScreen(),
      ),
      GoRoute(
        path: '/customer/category/:name',
        builder: (context, state) => CategoryShopsScreen(category: state.pathParameters['name']!),
      ),
      GoRoute(path: '/customer/offer', builder: (context, state) => OfferDetailsScreen(offer: state.extra as OfferModel)),
      GoRoute(path: '/customer/product', builder: (context, state) => ProductDetailsScreen(product: state.extra as ProductModel)),
      GoRoute(
        path: '/customer/product-reviews/:id/:name',
        builder: (context, state) => ProductReviewsScreen(
          productId: state.pathParameters['id']!,
          productName: state.pathParameters['name']!,
        ),
      ),
      GoRoute(path: '/customer/shop/:id', builder: (context, state) => ShopDetailScreen(shopId: state.pathParameters['id']!)),
      GoRoute(path: '/customer/notifications', builder: (context, state) => const CustomerNotificationsScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductRouteWidget(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/rider', builder: (context, state) => const RiderDashboard()),
      GoRoute(
        path: '/rider/order-details/:id',
        builder: (context, state) => OrderDetailsScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/rider/active-tasks', builder: (context, state) => const ActiveTasksScreen()),
      GoRoute(path: '/rider/performance', builder: (context, state) => const PerformanceDetailsScreen()),
      GoRoute(path: '/rider/reviews', builder: (context, state) => const RiderReviewsScreen()),
      GoRoute(path: '/rider/profile', builder: (context, state) => const RiderProfileScreen()),
      GoRoute(path: '/rider/history', builder: (context, state) => const RiderHistoryScreen()),
      GoRoute(path: '/rider/earnings', builder: (context, state) => const RiderEarningsScreen()),
      GoRoute(path: '/rider/vehicle', builder: (context, state) => const VehicleDetailsScreen()),
      GoRoute(path: '/rider/support', builder: (context, state) => const SupportCenterScreen()),
      GoRoute(path: '/rider/support-chat', builder: (context, state) => const SupportChatScreen()),
      GoRoute(path: '/rider/alerts', builder: (context, state) => const AlertsScreen()),
      GoRoute(path: '/rider/documents', builder: (context, state) => const DocumentsScreen()),
      GoRoute(path: '/support', builder: (context, state) => const SupportHubScreen()),
      GoRoute(
        path: '/support/create-ticket',
        builder: (context, state) => CreateTicketScreen(initialCategory: state.extra as String?),
      ),
      GoRoute(
        path: '/support/ticket-chat/:id',
        builder: (context, state) => TicketChatScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/support/live-chat/:id',
        builder: (context, state) => LiveChatScreen(chatId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/support/emergency', builder: (context, state) => const EmergencyReportScreen()),
      GoRoute(
        path: '/support/emergency-details/:id',
        builder: (context, state) => EmergencyDetailsScreen(reportId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/support/tickets', builder: (context, state) => const MyTicketsScreen()),
      GoRoute(
        path: '/chat/:orderId/:name',
        builder: (context, state) => ChatScreen(
          orderId: state.pathParameters['orderId']!,
          otherPartyName: state.pathParameters['name']!,
        ),
      ),
    ],
  );
});

class ProductRouteWidget extends StatelessWidget {
  final String productId;

  const ProductRouteWidget({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            return ProductDetailsScreen(product: ProductModel.fromFirestore(snapshot.data!));
          }
        }
        return const Scaffold(body: Center(child: Text('Product not found')));
      },
    );
  }
}

class RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userModelProvider, (_, __) => notifyListeners());
    _ref.listen(splashDurationProvider, (_, __) => notifyListeners());
  }
}