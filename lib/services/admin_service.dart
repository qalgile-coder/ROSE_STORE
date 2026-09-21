import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/shop_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/approval_model.dart';
import '../models/payout_model.dart';
import '../models/activity_model.dart';
import '../models/category_model.dart';
import '../models/offer_model.dart';
import '../models/system_settings_model.dart';
import '../models/coupon_model.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Manage Platform Settings
  Stream<SystemSettingsModel> getSystemSettings() {
    return _db.collection('settings').doc('platform').snapshots().map((doc) {
      if (!doc.exists) {
        // Return default settings if none exist
        return SystemSettingsModel(
          deliveryCharge: 150.0,
          taxPercentage: 5.0,
          platformCommission: 15.0,
          appVersion: '1.2.0',
          supportEmail: 'support@zenmartpro.com',
          supportPhone: '+92 300 1234567',
        );
      }
      return SystemSettingsModel.fromFirestore(doc);
    });
  }

  Future<void> updateSystemSettings(Map<String, dynamic> data) async {
    await _db.collection('settings').doc('platform').set(data, SetOptions(merge: true));
  }

  /// Manage Platform Categories
  Stream<List<CategoryModel>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.collection('categories').add(category.toMap());
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _db.collection('categories').doc(id).update(data);
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  /// Get stream of all activity logs
  Stream<List<ActivityModel>> getActivityLogs({DateTime? start}) {
    Query query = _db.collection('activity_logs').orderBy('timestamp', descending: true);
    if (start != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ActivityModel.fromFirestore(doc)).toList());
  }

  /// Get stream of all pending approvals
  Stream<List<ApprovalModel>> getPendingApprovals() {
    return _db
        .collection('approvals')
        .where('status', isEqualTo: ApprovalStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      final approvals = snapshot.docs.map((doc) => ApprovalModel.fromFirestore(doc)).toList();
      approvals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return approvals;
    });
  }

  /// Update approval status
  Future<void> updateApprovalStatus(String id, ApprovalStatus status) async {
    final approvalDoc = await _db.collection('approvals').doc(id).get();
    if (!approvalDoc.exists) return;
    
    final approval = ApprovalModel.fromFirestore(approvalDoc);
    final batch = _db.batch();

    // 1. Update the approval request itself
    batch.update(_db.collection('approvals').doc(id), {'status': status.name});

    // 2. Handle role-specific logic on approval
    if (status == ApprovalStatus.approved) {
       if (approval.type == ApprovalType.riderVerification) {
          // Verify rider and update their document status
          final Map<String, String> approvedDocs = {};
          final docUrls = approval.details['documentUrls'] as Map<String, dynamic>? ?? {};
          docUrls.forEach((k, v) => approvedDocs['documents.$k'] = 'approved');
          
          batch.update(_db.collection('users').doc(approval.applicantId), {
            ...approvedDocs,
            'verificationStatus': 'verified',
          });

          // Notify Rider
          _db.collection('users').doc(approval.applicantId).collection('notifications').add({
            'title': 'Identity Verified! ✅',
            'message': 'Your documents have been approved. You are now a verified rider.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'verification_success',
          });
       }
    }

    if (status == ApprovalStatus.rejected) {
       if (approval.type == ApprovalType.riderVerification) {
          batch.update(_db.collection('users').doc(approval.applicantId), {
            'verificationStatus': 'rejected',
          });
       }
    }

    await batch.commit();
  }

  /// Get stream of all payout requests
  Stream<List<PayoutModel>> getPayoutRequests() {
    return _db
        .collection('payouts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PayoutModel.fromFirestore(doc))
            .toList());
  }

  /// Update payout status
  Future<void> updatePayoutStatus(String id, PayoutStatus status, {String? txId, String? method}) async {
    final payoutDoc = await _db.collection('payouts').doc(id).get();
    if (!payoutDoc.exists) return;
    
    final payout = PayoutModel.fromFirestore(payoutDoc);
    final batch = _db.batch();

    Map<String, dynamic> updateData = {'status': status.name};
    
    if (status == PayoutStatus.paid) {
      updateData['processedAt'] = FieldValue.serverTimestamp();
      updateData['transactionId'] = txId;
      updateData['paymentMethod'] = method;
      
      // Notify user
      _db.collection('users').doc(payout.userId).collection('notifications').add({
        'title': 'Payout Successful ✅',
        'message': 'Rs ${payout.amount.toInt()} has been transferred to your account.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'payment_received',
      });
    }

    if (status == PayoutStatus.rejected) {
      // Refund money back to user's totalEarnings if rejected
      final userRef = _db.collection('users').doc(payout.userId);
      batch.update(userRef, {
        'totalEarnings': FieldValue.increment(payout.amount),
      });

      // Notify user
      _db.collection('users').doc(payout.userId).collection('notifications').add({
        'title': 'Payout Rejected ❌',
        'message': 'Your payout request for Rs ${payout.amount.toInt()} was rejected. Amount returned to balance.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'payout_rejected',
      });
    }

    batch.update(_db.collection('payouts').doc(id), updateData);
    await batch.commit();
  }

  /// Get stream of all customers
  Stream<List<UserModel>> getAllCustomers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Get stream of all vendors
  Stream<List<UserModel>> getAllVendors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'vendor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Update user status (active/suspended)
  Future<void> updateUserStatus(String uid, String status) async {
    await _db.collection('users').doc(uid).update({'status': status});
  }

  /// Update user basic details
  Future<void> updateUserDetails(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    // Also delete their shop if they are a vendor
    final userDoc = await _db.collection('users').doc(uid).get();
    final shopId = userDoc.data()?['shopId'];
    if (shopId != null) {
      await _db.collection('shops').doc(shopId).delete();
    }
    await _db.collection('users').doc(uid).delete();
  }

  /// Reset Password logic (Sending password reset email)
  Future<void> sendResetPasswordEmail(String email) async {
    // Typically this would use FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    // For now we simulate or use standard Firebase Auth if available in this context
  }

  /// Get user specific orders
  Stream<List<OrderModel>> getUserOrders(String userId, UserRole role) {
    String field = role == UserRole.customer ? 'customerId' : 
                   role == UserRole.vendor ? 'vendorId' : 'riderId';
    
    return _db.collection('orders')
        .where(field, isEqualTo: userId)
        .snapshots()
        .map((s) {
          final orders = s.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Get user specific payouts
  Stream<List<PayoutModel>> getUserPayouts(String userId) {
    return _db.collection('payouts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => PayoutModel.fromFirestore(doc)).toList());
  }

  /// Get stream of all riders
  Stream<List<UserModel>> getAllRiders() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'rider')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Update rider status (active/suspended)
  Future<void> updateRiderStatus(String uid, String status) async {
    await _db.collection('users').doc(uid).update({'status': status});
  }

  /// Delete rider
  Future<void> deleteRider(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  /// Get stream of all pending orders
  Stream<List<OrderModel>> getPendingOrders() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Get a single order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (doc.exists) return OrderModel.fromFirestore(doc);
    return null;
  }

  /// Get all orders
  Stream<List<OrderModel>> getAllOrders() {
    return _db
        .collection('orders')
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders.take(50).toList();
        });
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({'status': 'cancelled'});
  }

  /// Get stream of admin notifications
  Stream<List<NotificationModel>> getNotifications() {
    return _db
        .collection('admin_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('admin_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('admin_notifications').doc(notificationId).delete();
  }

  /// Get stream of orders based on time range
  Stream<List<OrderModel>> getOrdersStream({required DateTime start, required DateTime end}) {
    return _db
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  /// Get revenue stats based on time range
  Stream<double> getRevenueStream({required DateTime start, required DateTime end}) {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'delivered')
        .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('deliveredAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalAmount'] ?? 0.0).toDouble();
      }
      return total;
    });
  }

  /// Get stream of all shops
  Stream<List<ShopModel>> getAllShops() {
    return _db
        .collection('shops')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopModel.fromFirestore(doc))
            .toList());
  }

  /// Update shop status
  Future<void> updateShopStatus(String shopId, String status) async {
    await _db.collection('shops').doc(shopId).update({'status': status});
  }

  /// Delete shop
  Future<void> deleteShop(String shopId) async {
    await _db.collection('shops').doc(shopId).delete();
  }

  /// Manage Promotional Offers / Banners
  Stream<List<OfferModel>> getAllOffers() {
    return _db.collection('offers').orderBy('expiryDate', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList());
  }

  Future<void> addOffer(OfferModel offer) async {
    await _db.collection('offers').add(offer.toMap());
  }

  Future<void> deleteOffer(String id) async {
    await _db.collection('offers').doc(id).delete();
  }

  /// Assign Vendor to Shop
  Future<void> assignVendorToShop(String vendorId, String shopId, String shopName) async {
    final batch = _db.batch();
    
    // 1. Update User record
    batch.update(_db.collection('users').doc(vendorId), {'shopId': shopId});
    
    // 2. Update Shop record
    batch.update(_db.collection('shops').doc(shopId), {
      'vendorId': vendorId,
      'vendorName': shopName,
    });

    await batch.commit();
  }

  /// Assign Rider to Order
  Future<void> assignRiderToOrder(String orderId, String riderId, String riderName) async {
    await _db.collection('orders').doc(orderId).update({
      'riderId': riderId,
      'riderName': riderName,
      'status': OrderStatus.confirmed.name, // Usually goes to confirmed when rider assigned
    });
  }

  /// Global Coupon Management
  Stream<List<CouponModel>> getGlobalCoupons() {
    return _db.collection('coupons')
        .where('shopId', isNull: true) // Null shopId means global
        .snapshots()
        .map((s) => s.docs.map((doc) => CouponModel.fromFirestore(doc)).toList());
  }

  Future<void> addGlobalCoupon(CouponModel coupon) async {
    await _db.collection('coupons').add(coupon.toMap());
  }

  Future<void> deleteCoupon(String id) async {
    await _db.collection('coupons').doc(id).delete();
  }

  /// Create a notification (Helper for testing and system triggers)
  Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('admin_notifications').add({
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'data': data,
    });
  }
}
