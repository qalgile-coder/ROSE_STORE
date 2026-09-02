import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/rider_service.dart';
import '../services/cloudinary_service.dart';
import '../services/upload_service.dart';
import '../services/vendor_service.dart';
import '../services/admin_service.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';
import '../services/support_service.dart';
import '../services/emergency_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/notification_model.dart';
import '../models/vendor_notification_model.dart';
import '../models/rider_notification_model.dart';
import '../models/shop_model.dart';
import '../models/approval_model.dart';
import '../models/payout_model.dart';
import '../models/activity_model.dart';
import '../models/review_model.dart';
import '../models/coupon_model.dart';
import '../models/address_model.dart';
import '../models/category_model.dart';
import '../models/support_chat_model.dart';
import '../models/support_ticket_model.dart';
import '../models/emergency_report_model.dart';
import '../models/offer_model.dart';
import '../models/cart_model.dart';
import '../models/system_settings_model.dart';
import '../services/cache_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final authServiceProvider = Provider((ref) => AuthService());
final riderServiceProvider = Provider((ref) => RiderService());
final cloudinaryServiceProvider = Provider((ref) => CloudinaryService());
final uploadServiceProvider = Provider((ref) => UploadService(ref));
final vendorServiceProvider = Provider((ref) => VendorService());
final adminServiceProvider = Provider((ref) => AdminService());
final customerServiceProvider = Provider((ref) => CustomerService());
final orderServiceProvider = Provider((ref) => OrderService(ref.read(notificationServiceProvider)));
final supportServiceProvider = Provider((ref) => SupportService(ref.read(notificationServiceProvider)));
final emergencyServiceProvider = Provider((ref) => EmergencyService(ref.read(notificationServiceProvider)));
final notificationServiceProvider = Provider((ref) => NotificationService());

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) => results.first);
});

final splashDurationProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 3));
});

final forcedSplashProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userModelProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  
  if (authState.isLoading) {
    return; // Keep current state while auth is loading
  }

  final user = authState.asData?.value;
  
  if (user == null) {
    yield null;
  } else {
    // Save FCM Token when user logs in - Wrap in error handling
    try {
      ref.read(notificationServiceProvider).saveTokenToFirestore(user.uid);
    } catch (e) {
      debugPrint('FCM Token Save Failed (Non-critical): $e');
    }
    
    // Using a more resilient stream handling
    final stream = ref.read(authServiceProvider).getUserStream(user.uid);
    
    yield* stream.handleError((e) {
      debugPrint('Firestore User Stream Error: $e');
    });
  }
});

// --- RIDER PROVIDERS ---
final availableOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.rider) return Stream.value([]);
  return ref.watch(riderServiceProvider).getAvailableOrders(user.uid);
});

final activeRiderOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.rider) return Stream.value([]);
  return ref.watch(riderServiceProvider).getActiveRiderOrders(user.uid);
});

final riderHistoryProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.rider) return Stream.value([]);
  return ref.watch(riderServiceProvider).getRiderHistory(user.uid);
});

final todayRiderHistoryProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.rider) return Stream.value([]);
  return ref.watch(riderServiceProvider).getTodayRiderHistory(user.uid);
});

final riderNotificationsProvider = StreamProvider<List<RiderNotificationModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.rider) return Stream.value([]);
  return ref.watch(riderServiceProvider).getNotifications(user.uid);
});

final riderReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.rider) return Stream.value([]);
  return ref.watch(riderServiceProvider).getRiderReviews(user.uid);
});

final riderPayoutHistoryProvider = StreamProvider<List<PayoutModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.rider) return Stream.value([]);
  return ref.watch(riderServiceProvider).getPayoutHistory(user.uid);
});

// --- VENDOR PROVIDERS ---
final shopProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor || user.shopId == null) return Stream.value([]);
  return ref.watch(vendorServiceProvider).getShopProducts(user.shopId!);
});

final currentShopProvider = StreamProvider<ShopModel?>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor || user.shopId == null) return Stream.value(null);
  return ref.watch(vendorServiceProvider).getShopData(user.shopId!);
});

final lowStockProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor || user.shopId == null) return Stream.value([]);
  return ref.watch(vendorServiceProvider).getLowStockProducts(user.shopId!);
});

final shopReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor || user.shopId == null) return Stream.value([]);
  return ref.watch(vendorServiceProvider).getShopReviews(user.shopId!);
});

final shopReviewsProviderFromService = StreamProvider.family<List<ReviewModel>, String>((ref, shopId) {
  return ref.watch(vendorServiceProvider).getShopReviews(shopId);
});

final productReviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, productId) {
  return ref.watch(customerServiceProvider).getProductReviews(productId);
});

final incomingOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor || user.shopId == null) return Stream.value([]);
  return ref.watch(vendorServiceProvider).getIncomingOrders(user.shopId!);
});

final allShopOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor || user.shopId == null) return Stream.value([]);
  return ref.watch(vendorServiceProvider).getAllShopOrders(user.shopId!);
});

final shopCouponsProvider = StreamProvider<List<CouponModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor || user.shopId == null) return Stream.value([]);
  return ref.watch(vendorServiceProvider).getShopCoupons(user.shopId!);
});

final vendorNotificationsProvider = StreamProvider<List<VendorNotificationModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.vendor) return Stream.value([]);
  return ref.watch(vendorServiceProvider).getNotifications(user.uid);
});

final vendorActiveOrderTabProvider = StateProvider<int>((ref) => 0);

// --- CUSTOMER PROVIDERS ---
final customerAddressesProvider = StreamProvider<List<AddressModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.customer) return Stream.value([]);
  return ref.watch(customerServiceProvider).getSavedAddresses(user.uid);
});

final defaultAddressProvider = Provider<AddressModel?>((ref) {
  final addresses = ref.watch(customerAddressesProvider).asData?.value ?? [];
  try {
    return addresses.firstWhere((a) => a.isDefault);
  } catch (_) {
    return addresses.isNotEmpty ? addresses.first : null;
  }
});

final customerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.customer) return Stream.value([]);
  return ref.watch(customerServiceProvider).getCustomerOrders(user.uid);
});

final customerWishlistProvider = StreamProvider<List<ProductModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.customer) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('wishlist')
      .snapshots()
      .map((s) => s.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
});

final activeOffersProvider = StreamProvider<List<OfferModel>>((ref) {
  return ref.watch(customerServiceProvider).getActiveOffers();
});

final featuredShopsProvider = StreamProvider<List<ShopModel>>((ref) {
  return ref.watch(customerServiceProvider).getNearbyShops().map((shops) {
    // 1. First, try to get shops explicitly marked as featured
    final featured = shops.where((s) => s.isFeatured).toList();
    if (featured.isNotEmpty) return featured;
    
    // 2. Fallback: Show top-rated shops if no featured shops are set
    // This ensures the "Featured" section is never empty in a live app
    final sorted = List<ShopModel>.from(shops);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  });
});

final nearbyShopsProvider = StreamProvider<List<ShopModel>>((ref) {
  final connectivity = ref.watch(connectivityProvider).asData?.value;
  final isOffline = connectivity == ConnectivityResult.none;

  if (isOffline) {
    return Stream.value(CacheService.getCachedShops());
  }

  return ref.watch(customerServiceProvider).getNearbyShops().map((shops) {
    CacheService.cacheShops(shops);
    return shops;
  });
});

final trendingProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final connectivity = ref.watch(connectivityProvider).asData?.value;
  final isOffline = connectivity == ConnectivityResult.none;

  if (isOffline) {
    return Stream.value(CacheService.getCachedProducts());
  }

  return FirebaseFirestore.instance
      .collection('products')
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((s) {
        final products = s.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
        // Professional Trending: Sort by orderCount or rating in memory to avoid index errors for now
        products.sort((a, b) => b.orderCount.compareTo(a.orderCount));
        
        final topProducts = products.take(10).toList();
        CacheService.cacheProducts(topProducts);
        return topProducts;
      });
});

final allCategoriesProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(customerServiceProvider).getAllCategories();
});

final searchProductsProvider = StreamProvider.family<List<ProductModel>, String>((ref, query) {
  return ref.watch(customerServiceProvider).searchProducts(query);
});

final searchShopsProvider = StreamProvider.family<List<ShopModel>, String>((ref, query) {
  return ref.watch(customerServiceProvider).searchShops(query);
});

final shopDetailProvider = StreamProvider.family<ShopModel?, String>((ref, shopId) {
  return ref.watch(customerServiceProvider).getShopById(shopId);
});

final shopProductsByIdProvider = StreamProvider.family<List<ProductModel>, String>((ref, shopId) {
  return ref.watch(customerServiceProvider).getShopProducts(shopId);
});

final productDetailProvider = StreamProvider.family<ProductModel?, String>((ref, productId) {
  return FirebaseFirestore.instance.collection('products').doc(productId).snapshots().map((doc) {
    if (doc.exists) return ProductModel.fromFirestore(doc);
    return null;
  });
});

final categoryShopsProvider = StreamProvider.family<List<ShopModel>, String>((ref, category) {
  return ref.watch(customerServiceProvider).getCategoryShops(category);
});

final offerShopsProvider = StreamProvider.family<List<ShopModel>, List<String>>((ref, shopIds) {
  return ref.watch(customerServiceProvider).getShopsByIds(shopIds);
});

final offerProductsProvider = StreamProvider.family<List<ProductModel>, List<String>>((ref, productIds) {
  return ref.watch(customerServiceProvider).getProductsByIds(productIds);
});

// --- ADMIN PROVIDERS ---
final adminNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getNotifications();
});

final allShopsProvider = StreamProvider<List<ShopModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getAllShops();
});

final allRidersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getAllRiders();
});

final allPendingOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getPendingOrders();
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getAllOrders();
});

final allCustomersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getAllCustomers();
});

final allVendorsProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getAllVendors();
});

final pendingApprovalsProvider = StreamProvider<List<ApprovalModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getPendingApprovals();
});

final payoutRequestsProvider = StreamProvider<List<PayoutModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getPayoutRequests();
});

final allCategoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(adminServiceProvider).getCategories();
});

final allOffersProvider = StreamProvider<List<OfferModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getAllOffers();
});

final activityLogsProvider = StreamProvider.family<List<ActivityModel>, DateTime?>((ref, start) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value([]);
  return ref.watch(adminServiceProvider).getActivityLogs(start: start);
});

final systemSettingsProvider = StreamProvider<SystemSettingsModel>((ref) {
  return ref.watch(adminServiceProvider).getSystemSettings();
});

final globalCouponsProvider = StreamProvider<List<CouponModel>>((ref) {
  return ref.watch(adminServiceProvider).getGlobalCoupons();
});

// Admin Stats Providers
final totalShopsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0);
  return FirebaseFirestore.instance.collection('shops').snapshots().map((s) => s.docs.length);
});

final totalRidersCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0);
  return FirebaseFirestore.instance.collection('users')
      .where('role', isEqualTo: 'rider')
      .snapshots().map((s) => s.docs.length);
});

final totalCustomersCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0);
  return FirebaseFirestore.instance.collection('users')
      .where('role', isEqualTo: 'customer')
      .snapshots().map((s) => s.docs.length);
});

final pendingOrdersCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0);
  return FirebaseFirestore.instance.collection('orders')
      .where('status', isEqualTo: 'pending')
      .snapshots().map((s) => s.docs.length);
});

final pendingPayoutsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0);
  return FirebaseFirestore.instance.collection('payouts')
      .where('status', isEqualTo: 'pending')
      .snapshots().map((s) => s.docs.length);
});

// Revenue Providers
final dailyRevenueProvider = StreamProvider<double>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0.0);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return ref.watch(adminServiceProvider).getRevenueStream(start: start, end: end);
});

final weeklyRevenueProvider = StreamProvider<double>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0.0);
  final now = DateTime.now();
  final start = now.subtract(Duration(days: now.weekday - 1));
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return ref.watch(adminServiceProvider).getRevenueStream(start: start, end: end);
});

final monthlyRevenueProvider = StreamProvider<double>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.role != UserRole.superAdmin) return Stream.value(0.0);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return ref.watch(adminServiceProvider).getRevenueStream(start: start, end: end);
});

// --- SUPPORT & EMERGENCY PROVIDERS ---
final supportChatProvider = StreamProvider.family<SupportChatModel?, String>((ref, chatId) {
  return ref.watch(supportServiceProvider).getChatStream(chatId);
});

final customerSupportChatProvider = StreamProvider<String?>((ref) async* {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null) {
    yield null;
  } else {
    // This is a bit tricky for a pure StreamProvider if we want it to be auto-creating.
    // For now, we'll assume the UI calls getOrCreateChat.
    // We'll just return the chatId if it exists.
    final db = FirebaseFirestore.instance;
    final snapshots = db.collection('support_chats')
        .where('customerId', isEqualTo: user.uid)
        .limit(1)
        .snapshots();
    
    await for (final snap in snapshots) {
      if (snap.docs.isNotEmpty) {
        yield snap.docs.first.id;
      } else {
        yield null;
      }
    }
  }
});

final supportMessagesProvider = StreamProvider.family<List<SupportMessageModel>, String>((ref, chatId) {
  return ref.watch(supportServiceProvider).getSupportMessages(chatId);
});

final customerEmergencyReportsProvider = StreamProvider<List<EmergencyReportModel>>((ref) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null) return Stream.value([]);
  return ref.watch(emergencyServiceProvider).getCustomerReports(user.uid);
});

final emergencyReportStreamProvider = StreamProvider.family<EmergencyReportModel?, String>((ref, reportId) {
  return ref.watch(emergencyServiceProvider).getReportStream(reportId);
});

final emergencyTimelineProvider = StreamProvider.family<List<EmergencyTimelineEvent>, String>((ref, reportId) {
  return ref.watch(emergencyServiceProvider).getTimeline(reportId);
});

final emergencyMessagesProvider = StreamProvider.family<List<SupportMessageModel>, String>((ref, reportId) {
  return ref.watch(emergencyServiceProvider).getEmergencyMessages(reportId);
});

// --- CART ---
class CartNotifier extends StateNotifier<CartModel> {
  CartNotifier() : super(CartModel());

  void addItem(ProductModel product, {String? shopName, String? shopImageUrl}) {
    if (state.items.isEmpty) {
      state = CartModel(
        items: {product.id: CartItem(product: product)},
        shopId: product.shopId,
        shopName: shopName,
        shopImageUrl: shopImageUrl,
      );
      return;
    }

    if (state.items.containsKey(product.id)) {
      state = CartModel(
        items: {
          ...state.items,
          product.id: state.items[product.id]!.copyWith(
            quantity: state.items[product.id]!.quantity + 1,
          ),
        },
        shopId: state.shopId,
        shopName: state.shopName,
        shopImageUrl: state.shopImageUrl,
      );
    } else {
      state = CartModel(
        items: {
          ...state.items,
          product.id: CartItem(product: product),
        },
        shopId: state.shopId,
        shopName: state.shopName,
        shopImageUrl: state.shopImageUrl,
      );
    }
  }

  void removeItem(String productId) {
    if (!state.items.containsKey(productId)) return;
    if (state.items[productId]!.quantity > 1) {
      state = CartModel(
        items: {
          ...state.items,
          productId: state.items[productId]!.copyWith(
            quantity: state.items[productId]!.quantity - 1,
          ),
        },
        shopId: state.shopId,
        shopName: state.shopName,
        shopImageUrl: state.shopImageUrl,
      );
    } else {
      final newItems = Map<String, CartItem>.from(state.items);
      newItems.remove(productId);
      if (newItems.isEmpty) {
        state = CartModel();
      } else {
        state = CartModel(
          items: newItems,
          shopId: state.shopId,
          shopName: state.shopName,
          shopImageUrl: state.shopImageUrl,
        );
      }
    }
  }

  void clearCart() {
    state = CartModel();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartModel>((ref) {
  return CartNotifier();
});

// --- VENDOR ANALYTICS PROVIDERS ---
final vendorSalesAnalyticsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, period) {
  final user = ref.watch(userModelProvider).asData?.value;
  if (user == null || user.shopId == null) return Stream.value({});
  
  return ref.watch(vendorServiceProvider).getAllShopOrders(user.shopId!).map((orders) {
    final now = DateTime.now();
    DateTime start;
    if (period == 'Daily') {
      start = DateTime(now.year, now.month, now.day);
    } else if (period == 'Weekly') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else {
      start = DateTime(now.year, now.month, 1);
    }
    
    final filtered = orders.where((o) => o.createdAt.isAfter(start)).toList();
    
    double revenue = 0;
    int itemsSold = 0;
    Map<String, Map<String, dynamic>> productStats = {};
    Map<int, double> chartMap = {};
    
    for (var o in filtered) {
      if (o.status == OrderStatus.delivered) {
        final amount = o.totalAmount - o.deliveryFee;
        revenue += amount;
        
        // Items & Product Stats
        for (var item in o.items) {
          final pid = item['productId'] as String?;
          if (pid == null) continue;
          final qty = (item['quantity'] ?? 1) as int;
          final price = (item['price'] ?? 0.0).toDouble();
          itemsSold += qty;
          
          productStats.putIfAbsent(pid, () => {
            'name': item['name'] ?? 'Product',
            'sales': 0,
            'revenue': 0.0,
          });
          productStats[pid]!['sales'] = (productStats[pid]!['sales'] as int) + qty;
          productStats[pid]!['revenue'] = (productStats[pid]!['revenue'] as double) + (price * qty);
        }

        // Chart Logic
        int key;
        if (period == 'Daily') {
          key = o.createdAt.hour;
        } else if (period == 'Weekly') {
          key = o.createdAt.weekday;
        } else {
          key = o.createdAt.day;
        }
        chartMap[key] = (chartMap[key] ?? 0) + amount;
      }
    }
    
    final topProducts = productStats.values.toList();
    topProducts.sort((a, b) => (b['sales'] as int).compareTo(a['sales'] as int));
    
    // Zero-fill the chart map for a continuous line
    int maxPoints = period == 'Daily' ? 23 : (period == 'Weekly' ? 7 : 31);
    int minPoint = period == 'Weekly' ? 1 : 0;
    for (int i = minPoint; i <= maxPoints; i++) {
      chartMap.putIfAbsent(i, () => 0.0);
    }
    
    return {
      'revenue': revenue,
      'orders': filtered.length,
      'itemsSold': itemsSold,
      'avgValue': filtered.isEmpty ? 0.0 : revenue / filtered.length,
      'topProducts': topProducts.take(5).toList(),
      'chartMap': chartMap,
    };
  });
});

