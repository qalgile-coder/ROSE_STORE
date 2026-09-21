import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/vendor_notification_model.dart';
import '../models/review_model.dart';
import '../models/shop_model.dart';
import '../models/coupon_model.dart';

class VendorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get shop data
  Stream<ShopModel?> getShopData(String shopId) {
    return _db.collection('shops').doc(shopId).snapshots().map((doc) {
      if (doc.exists) return ShopModel.fromFirestore(doc);
      return null;
    }).handleError((e) {
      debugPrint('Firestore Error (Shop Data): $e');
      return null;
    });
  }

  Future<void> updateShopData(String shopId, Map<String, dynamic> data) async {
    await _db.collection('shops').doc(shopId).update(data);
  }

  Future<void> updateShopLogo(String shopId, String logoUrl) async {
    await _db.collection('shops').doc(shopId).update({'logoUrl': logoUrl});
  }

  Future<void> updateShopBanner(String shopId, String bannerUrl) async {
    await _db.collection('shops').doc(shopId).update({'bannerImage': bannerUrl});
  }

  /// Toggle shop status (online/offline)
  Future<void> updateShopStatus(String shopId, String status) async {
    await _db.collection('shops').doc(shopId).update({'status': status});
  }

  /// Get stream of vendor notifications
  Stream<List<VendorNotificationModel>> getNotifications(String vendorId) {
    return _db
        .collection('users')
        .doc(vendorId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VendorNotificationModel.fromFirestore(doc))
            .toList())
        .handleError((e) {
      debugPrint('Firestore Error (Vendor Notifications): $e');
      return <VendorNotificationModel>[];
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String vendorId, String notificationId) async {
    await _db
        .collection('users')
        .doc(vendorId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Delete notification
  Future<void> deleteNotification(String vendorId, String notificationId) async {
    await _db
        .collection('users')
        .doc(vendorId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Add a new product to Firestore
  Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add(product.toMap());
  }

  /// Get stream of products for a specific shop
  Stream<List<ProductModel>> getShopProducts(String shopId) {
    return _db
        .collection('products')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  /// Get stream of low stock products for a specific shop
  Stream<List<ProductModel>> getLowStockProducts(String shopId, {int threshold = 5}) {
    return _db
        .collection('products')
        .where('shopId', isEqualTo: shopId)
        .where('stock', isLessThan: threshold)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
  }

  /// Update an existing product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(productId).update(data);
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// Get stream of incoming orders for a shop (Pending)
  Stream<List<OrderModel>> getIncomingOrders(String shopId) {
    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: OrderStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    }).handleError((e) {
      debugPrint('Firestore Error (Incoming Orders): $e');
      // On error, we emit an empty list so the UI doesn't hang
    });
  }

  /// Get stream of all orders for a shop
  Stream<List<OrderModel>> getAllShopOrders(String shopId) {
    return _db
        .collection('orders')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    }).handleError((e) {
      debugPrint('Firestore Error (All Shop Orders): $e');
    });
  }

  /// Update Order Status (Accept/Reject/Complete)
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.collection('orders').doc(orderId).update({'status': status.name});
  }

  /// Get a single order
  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (doc.exists) return OrderModel.fromFirestore(doc);
    return null;
  }

  /// Get stream of a single order
  Stream<OrderModel?> getShopOrderStream(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      if (doc.exists) return OrderModel.fromFirestore(doc);
      return null;
    });
  }

  /// Get stream of reviews for a specific shop
  Stream<List<ReviewModel>> getShopReviews(String shopId) {
    return _db
        .collection('shops')
        .doc(shopId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  /// Reply to a review
  Future<void> replyToReview(String shopId, String reviewId, String reply) async {
    await _db
        .collection('shops')
        .doc(shopId)
        .collection('reviews')
        .doc(reviewId)
        .update({'reply': reply});
  }

  /// Add Coupon
  Future<void> addCoupon(CouponModel coupon) async {
    await _db.collection('coupons').add(coupon.toMap());
  }

  /// Update Coupon
  Future<void> updateCoupon(String couponId, Map<String, dynamic> data) async {
    await _db.collection('coupons').doc(couponId).update(data);
  }

  /// Delete Coupon
  Future<void> deleteCoupon(String couponId) async {
    await _db.collection('coupons').doc(couponId).delete();
  }

  /// Get stream of coupons for a specific shop
  Stream<List<CouponModel>> getShopCoupons(String shopId) {
    return _db
        .collection('coupons')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CouponModel.fromFirestore(doc)).toList());
  }

  /// Payout and Bank Account logic
  Future<void> updateBankDetails(String vendorId, Map<String, dynamic> bankDetails) async {
    await _db.collection('users').doc(vendorId).update({
      'bankDetails': bankDetails,
    });
  }

  Future<void> requestWithdrawal(String vendorId, double amount, String role) async {
    // 1. Get user document
    final userDoc = await _db.collection('users').doc(vendorId).get();
    final earnings = (userDoc.data()?['totalEarnings'] ?? 0.0).toDouble();

    if (amount > earnings) {
      throw Exception('Insufficient balance');
    }

    // 2. Create withdrawal request
    await _db.collection('payouts').add({
      'userId': vendorId,
      'userName': userDoc.data()?['name'] ?? 'Unknown',
      'userType': 'vendor',
      'amount': amount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'bankDetails': userDoc.data()?['bankDetails'] ?? {},
    });

    // 3. Deduct from totalEarnings
    await _db.collection('users').doc(vendorId).update({
      'totalEarnings': FieldValue.increment(-amount),
    });
  }
}
