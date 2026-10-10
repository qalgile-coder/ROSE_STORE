import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

import '../core/providers.dart';
import '../models/user_model.dart';
import '../screens/splash_screen.dart';
import '../screens/developer_profile_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../screens/verify_email_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/add_vendor_screen.dart';
import '../features/admin/add_rider_screen.dart';
import '../features/admin/notifications_screen.dart';
import '../features/admin/admin_profile_screen.dart';
import '../features/admin/analytics_dashboard_screen.dart';
import '../features/admin/all_shops_screen.dart';
import '../features/admin/rider_management_screen.dart';
import '../features/admin/pending_orders_screen.dart';
import '../features/admin/customer_management_screen.dart';
import '../features/admin/vendor_management_screen.dart';
import '../features/admin/approval_center_screen.dart';
import '../features/admin/payout_management_screen.dart';
import '../features/admin/system_settings_screen.dart';
import '../features/admin/system_info_screen.dart';
import '../features/admin/activity_log_screen.dart';
import '../features/admin/shop_management_screen.dart';
import '../features/admin/category_management_screen.dart';
import '../features/admin/coupon_management_screen.dart' as admin;
import '../features/admin/user_management_screen.dart';
import '../features/admin/support_list_screen.dart';
import '../features/admin/support_chat_detail_screen.dart';
import '../features/admin/order_management_screen.dart';
import '../features/admin/user_history_screen.dart';
import '../features/admin/order_map_screen.dart';
import '../features/vendor/vendor_dashboard.dart';
import '../features/vendor/add_product_screen.dart';
import '../features/vendor/vendor_notifications_screen.dart';
import '../features/vendor/vendor_profile_screen.dart';
import '../features/vendor/sales_analytics_screen.dart';
import '../features/vendor/vendor_orders_screen.dart';
import '../features/vendor/vendor_order_details_screen.dart';
import '../features/vendor/product_management_screen.dart';
import '../features/vendor/low_stock_screen.dart';
import '../features/vendor/vendor_reviews_screen.dart';
import '../features/vendor/edit_shop_screen.dart';
import '../features/vendor/coupon_management_screen.dart';
import '../features/vendor/vendor_earnings_screen.dart';
import '../features/customer/customer_home.dart';
import '../features/customer/shop_detail_screen.dart';
import '../features/customer/customer_profile_screen.dart';
import '../features/customer/address_management_screen.dart';
import '../features/customer/search_screen.dart';
import '../features/customer/cart_screen.dart';
import '../features/customer/checkout_screen.dart';
import '../features/customer/order_success_screen.dart';
import '../features/customer/customer_orders_screen.dart';
import '../features/customer/customer_order_details_screen.dart';
import '../features/customer/category_shops_screen.dart';
import '../features/customer/featured_shops_screen.dart';
import '../features/customer/nearby_shops_screen.dart';
import '../features/customer/trending_products_screen.dart';
import '../features/customer/customer_all_products_screen.dart';
import '../features/customer/product_reviews_screen.dart';
import '../features/customer/offer_details_screen.dart';
import '../features/customer/product_details_screen.dart';
import '../features/customer/notifications_screen.dart';
import '../features/customer/wishlist_screen.dart';
import '../models/offer_model.dart';
import '../models/product_model.dart';
import '../features/rider/rider_dashboard.dart';
import '../features/rider/order_details_screen.dart';
import '../features/rider/active_tasks_screen.dart';
import '../features/rider/performance_details_screen.dart';
import '../features/rider/rider_reviews_screen.dart';
import '../features/rider/rider_profile_screen.dart';
import '../features/rider/history_screen.dart';
import '../features/rider/earnings_screen.dart';
import '../features/rider/vehicle_details_screen.dart';
import '../features/rider/support_center_screen.dart';
import '../features/rider/alerts_screen.dart';
import '../features/rider/documents_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/support_chat_screen.dart';
import '../features/support/screens/support_hub_screen.dart';
import '../features/support/screens/create_ticket_screen.dart';
import '../features/support/screens/ticket_chat_screen.dart';
import '../features/support/screens/my_tickets_screen.dart';
import '../features/support/screens/live_chat_screen.dart';
import '../features/support/screens/emergency_report_screen.dart';
import '../features/support/screens/emergency_details_screen.dart';

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

      // فحص وضع الصيانة أولاً[cite: 10]
      if (settings?.maintenanceMode == true) {
        final isSuperAdmin = userModel.valueOrNull?.role == UserRole.superAdmin;
        if (!isSuperAdmin) {
          return currentPath == '/maintenance' ? null : '/maintenance';
        }
      }

      if (splashWait.isLoading) return null;
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;

      // 1. إذا لم يكن مسجلاً للدخول إطلاقاً[cite: 10]
      if (user == null) {
        final isAuthScreen = currentPath == '/login' ||
            currentPath == '/welcome' ||
            currentPath == '/signup';
        return isAuthScreen ? null : '/welcome';
      }

      // 2. فحص حالة التحقق من البريد الإلكتروني[cite: 10]
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && !firebaseUser.emailVerified) {
        // إذا كان المستخدم في شاشة الـ Signup أو Login أو Welcome أو Verify-Email، 
        // نسمح له بالبقاء أو التنقل بحرية دون إجبار قسري، لكي يعمل زر الرجوع من التحقق إلى التسجيل بسلاسة.[cite: 10]
        if (currentPath == '/verify-email' ||
            currentPath == '/signup' ||
            currentPath == '/login' ||
            currentPath == '/welcome') {
          return null;
        }
        return '/verify-email';
      }

      // 3. إذا كان التحميل جارياً لنموذج المستخدم[cite: 10]
      if (userModel.isLoading) return null;

      final model = userModel.valueOrNull;

      if (userModel.hasError || model == null) {
        final isAuthScreen = currentPath == '/login' ||
            currentPath == '/welcome' ||
            currentPath == '/signup' ||
            currentPath == '/verify-email';
        if (isAuthScreen || currentPath == '/') return null;
        return '/welcome';
      }

      // 4. التوجيه بناءً على الدور إذا كان في الشاشات العامة[cite: 10]
      final isPublicScreen = currentPath == '/login' ||
          currentPath == '/welcome' ||
          currentPath == '/signup' ||
          currentPath == '/verify-email' ||
          currentPath == '/';

      if (isPublicScreen) {
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
      GoRoute(path: '/', pageBuilder: (context, state) => _buildSmoothTransition(const SplashScreen(), state)),
      GoRoute(path: '/developer-profile', pageBuilder: (context, state) => _buildSmoothTransition(const DeveloperProfileScreen(), state)),
      GoRoute(
        path: '/maintenance',
        pageBuilder: (context, state) => _buildSmoothTransition(
          Scaffold(
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
          state,
        ),
      ),
      GoRoute(path: '/welcome', pageBuilder: (context, state) => _buildSmoothTransition(const WelcomeScreen(), state)),
      GoRoute(path: '/login', pageBuilder: (context, state) => _buildSmoothTransition(const LoginScreen(), state)),
      GoRoute(path: '/signup', pageBuilder: (context, state) => _buildSmoothTransition(const SignupScreen(), state)),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final email = (state.extra as String?) ?? FirebaseAuth.instance.currentUser?.email ?? '';
          return _buildSmoothTransition(VerifyEmailScreen(email: email), state);
        },
      ),
      GoRoute(path: '/admin', pageBuilder: (context, state) => _buildSmoothTransition(const AdminDashboard(), state)),
      GoRoute(path: '/admin/add-vendor', pageBuilder: (context, state) => _buildSmoothTransition(const AddVendorScreen(), state)),
      GoRoute(path: '/admin/add-rider', pageBuilder: (context, state) => _buildSmoothTransition(const AddRiderScreen(), state)),
      GoRoute(path: '/admin/notifications', pageBuilder: (context, state) => _buildSmoothTransition(const NotificationsScreen(), state)),
      GoRoute(path: '/admin/profile', pageBuilder: (context, state) => _buildSmoothTransition(const AdminProfileScreen(), state)),
      GoRoute(path: '/admin/analytics', pageBuilder: (context, state) => _buildSmoothTransition(const AnalyticsDashboardScreen(), state)),
      GoRoute(path: '/admin/all-shops', pageBuilder: (context, state) => _buildSmoothTransition(const AllShopsScreen(), state)),
      GoRoute(path: '/admin/shops', pageBuilder: (context, state) => _buildSmoothTransition(const ShopManagementScreen(), state)),
      GoRoute(path: '/admin/categories', pageBuilder: (context, state) => _buildSmoothTransition(const CategoryManagementScreen(), state)),
      GoRoute(path: '/admin/coupons', pageBuilder: (context, state) => _buildSmoothTransition(const admin.CouponManagementScreen(), state)),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (context, state) => _buildSmoothTransition(
          UserManagementScreen(
            initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0,
          ),
          state,
        ),
      ),
      GoRoute(
        path: '/admin/riders',
        pageBuilder: (context, state) => _buildSmoothTransition(
          Scaffold(
            appBar: AppBar(title: const Text('Rider Management', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
            body: const RiderManagementScreen(),
          ),
          state,
        ),
      ),
      GoRoute(path: '/admin/pending-orders', pageBuilder: (context, state) => _buildSmoothTransition(const PendingOrdersScreen(), state)),
      GoRoute(
        path: '/admin/customers',
        pageBuilder: (context, state) => _buildSmoothTransition(
          Scaffold(
            appBar: AppBar(title: const Text('Customer Management', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
            body: const CustomerManagementScreen(),
          ),
          state,
        ),
      ),
      GoRoute(
        path: '/admin/vendors',
        pageBuilder: (context, state) => _buildSmoothTransition(
          Scaffold(
            appBar: AppBar(title: const Text('Vendor Management', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true),
            body: const VendorManagementScreen(),
          ),
          state,
        ),
      ),
      GoRoute(path: '/admin/approvals', pageBuilder: (context, state) => _buildSmoothTransition(const ApprovalCenterScreen(), state)),
      GoRoute(path: '/admin/payouts', pageBuilder: (context, state) => _buildSmoothTransition(const PayoutManagementScreen(), state)),
      GoRoute(path: '/admin/system', pageBuilder: (context, state) => _buildSmoothTransition(const SystemSettingsScreen(), state)),
      GoRoute(path: '/admin/system-info', pageBuilder: (context, state) => _buildSmoothTransition(const SystemInfoScreen(), state)),
      GoRoute(path: '/admin/activity-log', pageBuilder: (context, state) => _buildSmoothTransition(const ActivityLogScreen(), state)),
      GoRoute(path: '/admin/orders', pageBuilder: (context, state) => _buildSmoothTransition(const OrderManagementScreen(), state)),
      GoRoute(path: '/admin/order-map', pageBuilder: (context, state) => _buildSmoothTransition(const OrderMapScreen(), state)),
      GoRoute(
        path: '/admin/user-history/:userId/:role',
        pageBuilder: (context, state) => _buildSmoothTransition(
          UserHistoryScreen(
            userId: state.pathParameters['userId']!,
            role: UserRole.values.firstWhere(
              (e) => e.name == state.pathParameters['role'],
              orElse: () => UserRole.unknown,
            ),
          ),
          state,
        ),
      ),
      GoRoute(path: '/admin/support', pageBuilder: (context, state) => _buildSmoothTransition(const SupportListScreen(), state)),
      GoRoute(
        path: '/admin/support-chat/:userId/:userName',
        pageBuilder: (context, state) => _buildSmoothTransition(
          SupportChatDetailScreen(
            userId: state.pathParameters['userId']!,
            userName: state.pathParameters['userName']!,
          ),
          state,
        ),
      ),
      GoRoute(path: '/vendor', pageBuilder: (context, state) => _buildSmoothTransition(const VendorDashboard(), state)),
      GoRoute(path: '/vendor/add-product', pageBuilder: (context, state) => _buildSmoothTransition(const AddProductScreen(), state)),
      GoRoute(path: '/vendor/notifications', pageBuilder: (context, state) => _buildSmoothTransition(const VendorNotificationsScreen(), state)),
      GoRoute(path: '/vendor/profile', pageBuilder: (context, state) => _buildSmoothTransition(const VendorProfileScreen(), state)),
      GoRoute(path: '/vendor/edit-shop', pageBuilder: (context, state) => _buildSmoothTransition(const EditShopScreen(), state)),
      GoRoute(path: '/vendor/analytics', pageBuilder: (context, state) => _buildSmoothTransition(const VendorSalesAnalyticsScreen(), state)),
      GoRoute(path: '/vendor/orders', pageBuilder: (context, state) => _buildSmoothTransition(const VendorOrdersScreen(), state)),
      GoRoute(
        path: '/vendor/order-details/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(VendorOrderDetailsScreen(orderId: state.pathParameters['id']!), state),
      ),
      GoRoute(path: '/vendor/products', pageBuilder: (context, state) => _buildSmoothTransition(const ProductManagementScreen(), state)),
      GoRoute(path: '/vendor/low-stock', pageBuilder: (context, state) => _buildSmoothTransition(const LowStockScreen(), state)),
      GoRoute(path: '/vendor/reviews', pageBuilder: (context, state) => _buildSmoothTransition(const VendorReviewsScreen(), state)),
      GoRoute(path: '/vendor/coupons', pageBuilder: (context, state) => _buildSmoothTransition(const CouponManagementScreen(), state)),
      GoRoute(path: '/vendor/earnings', pageBuilder: (context, state) => _buildSmoothTransition(const VendorEarningsScreen(), state)),
      GoRoute(path: '/customer', pageBuilder: (context, state) => _buildSmoothTransition(const CustomerHome(), state)),
      GoRoute(path: '/customer/profile', pageBuilder: (context, state) => _buildSmoothTransition(const CustomerProfileScreen(), state)),
      GoRoute(path: '/customer/addresses', pageBuilder: (context, state) => _buildSmoothTransition(const AddressManagementScreen(), state)),
      GoRoute(path: '/customer/search', pageBuilder: (context, state) => _buildSmoothTransition(const CustomerSearchScreen(), state)),
      GoRoute(path: '/customer/wishlist', pageBuilder: (context, state) => _buildSmoothTransition(const WishlistScreen(), state)),
      GoRoute(path: '/customer/cart', pageBuilder: (context, state) => _buildSmoothTransition(const CartScreen(), state)),
      GoRoute(path: '/customer/checkout', pageBuilder: (context, state) => _buildSmoothTransition(const CheckoutScreen(), state)),
      GoRoute(path: '/customer/orders', pageBuilder: (context, state) => _buildSmoothTransition(const CustomerOrdersScreen(), state)),
      GoRoute(
        path: '/customer/order-details/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(CustomerOrderDetailsScreen(orderId: state.pathParameters['id']!), state),
      ),
      GoRoute(
        path: '/customer/order-success/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(OrderSuccessScreen(orderId: state.pathParameters['id']!), state),
      ),
      GoRoute(path: '/customer/featured-shops', pageBuilder: (context, state) => _buildSmoothTransition(const FeaturedShopsScreen(), state)),
      GoRoute(path: '/customer/nearby-shops', pageBuilder: (context, state) => _buildSmoothTransition(const NearbyShopsScreen(), state)),
      GoRoute(path: '/customer/trending-products', pageBuilder: (context, state) => _buildSmoothTransition(const TrendingProductsScreen(), state)),
      GoRoute(
        path: '/customer/all-products',
        pageBuilder: (context, state) => _buildSmoothTransition(const CustomerAllProductsScreen(), state),
      ),
      GoRoute(
        path: '/customer/category/:name',
        pageBuilder: (context, state) => _buildSmoothTransition(CategoryShopsScreen(category: state.pathParameters['name']!), state),
      ),
      GoRoute(path: '/customer/offer', pageBuilder: (context, state) => _buildSmoothTransition(OfferDetailsScreen(offer: state.extra as OfferModel), state)),
      
      // مسار تفاصيل المنتج المُحدث لدعم الكائن أو جلبه عبر المعرف ديناميكياً بدون أخطاء[cite: 10]
      GoRoute(
        path: '/customer/product',
        pageBuilder: (context, state) {
          if (state.extra is ProductModel) {
            return _buildSmoothTransition(ProductDetailsScreen(product: state.extra as ProductModel), state);
          }
          return _buildSmoothTransition(const Scaffold(body: Center(child: Text('Invalid product data'))), state);
        },
      ),
      GoRoute(
        path: '/customer/product/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(ProductRouteWidget(productId: state.pathParameters['id']!), state),
      ),

      GoRoute(
        path: '/customer/product-reviews/:id/:name',
        pageBuilder: (context, state) => _buildSmoothTransition(
          ProductReviewsScreen(
            productId: state.pathParameters['id']!,
            productName: state.pathParameters['name']!,
          ),
          state,
        ),
      ),
      GoRoute(path: '/customer/shop/:id', pageBuilder: (context, state) => _buildSmoothTransition(ShopDetailScreen(shopId: state.pathParameters['id']!), state)),
      GoRoute(path: '/customer/notifications', pageBuilder: (context, state) => _buildSmoothTransition(const NotificationsScreen(), state)),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(ProductRouteWidget(productId: state.pathParameters['id']!), state),
      ),
      GoRoute(path: '/rider', pageBuilder: (context, state) => _buildSmoothTransition(const RiderDashboard(), state)),
      GoRoute(
        path: '/rider/order-details/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(OrderDetailsScreen(orderId: state.pathParameters['id']!), state),
      ),
      GoRoute(path: '/rider/active-tasks', pageBuilder: (context, state) => _buildSmoothTransition(const ActiveTasksScreen(), state)),
      GoRoute(path: '/rider/performance', pageBuilder: (context, state) => _buildSmoothTransition(const PerformanceDetailsScreen(), state)),
      GoRoute(path: '/rider/reviews', pageBuilder: (context, state) => _buildSmoothTransition(const RiderReviewsScreen(), state)),
      GoRoute(path: '/rider/profile', pageBuilder: (context, state) => _buildSmoothTransition(const RiderProfileScreen(), state)),
      GoRoute(path: '/rider/history', pageBuilder: (context, state) => _buildSmoothTransition(const RiderHistoryScreen(), state)),
      GoRoute(path: '/rider/earnings', pageBuilder: (context, state) => _buildSmoothTransition(const RiderEarningsScreen(), state)),
      GoRoute(path: '/rider/vehicle', pageBuilder: (context, state) => _buildSmoothTransition(const VehicleDetailsScreen(), state)),
      GoRoute(path: '/rider/support', pageBuilder: (context, state) => _buildSmoothTransition(const SupportCenterScreen(), state)),
      GoRoute(path: '/rider/support-chat', pageBuilder: (context, state) => _buildSmoothTransition(const SupportChatScreen(), state)),
      GoRoute(path: '/rider/alerts', pageBuilder: (context, state) => _buildSmoothTransition(const AlertsScreen(), state)),
      GoRoute(path: '/rider/documents', pageBuilder: (context, state) => _buildSmoothTransition(const DocumentsScreen(), state)),
      GoRoute(path: '/support', pageBuilder: (context, state) => _buildSmoothTransition(const SupportHubScreen(), state)),
      GoRoute(
        path: '/support/create-ticket',
        pageBuilder: (context, state) => _buildSmoothTransition(CreateTicketScreen(initialCategory: state.extra as String?), state),
      ),
      GoRoute(
        path: '/support/ticket-chat/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(TicketChatScreen(ticketId: state.pathParameters['id']!), state),
      ),
      GoRoute(
        path: '/support/live-chat/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(LiveChatScreen(chatId: state.pathParameters['id']!), state),
      ),
      GoRoute(path: '/support/emergency', pageBuilder: (context, state) => _buildSmoothTransition(const EmergencyReportScreen(), state)),
      GoRoute(
        path: '/support/emergency-details/:id',
        pageBuilder: (context, state) => _buildSmoothTransition(EmergencyDetailsScreen(reportId: state.pathParameters['id']!), state),
      ),
      GoRoute(path: '/support/tickets', pageBuilder: (context, state) => _buildSmoothTransition(const MyTicketsScreen(), state)),
      GoRoute(
        path: '/chat/:orderId/:name',
        pageBuilder: (context, state) => _buildSmoothTransition(
          ChatScreen(
            orderId: state.pathParameters['orderId']!,
            otherPartyName: state.pathParameters['name']!,
          ),
          state,
        ),
      ),
    ],
  );
});

// دالة مساعدة لتوفير انتقال احترافي للغاية (Ultra-Smooth Custom Transition)
CustomTransitionPage<void> _buildSmoothTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.02); // حركة صعود خفيفة ومريحة جداً
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      var fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
  );
}

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