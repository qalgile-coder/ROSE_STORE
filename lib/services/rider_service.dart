import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/rider_notification_model.dart';
import '../models/review_model.dart';
import '../models/payout_model.dart';

class RiderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get stream of rider notifications
  Stream<List<RiderNotificationModel>> getNotifications(String riderId) {
    return _db
        .collection('users')
        .doc(riderId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RiderNotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Update online/offline status
  Future<void> toggleOnlineStatus(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).update({'isOnline': isOnline});
  }

  /// Get available orders for riders
  Stream<List<OrderModel>> getAvailableOrders(String riderId) {
    return _db
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.confirmed.name)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      // Remove orders already rejected by this rider
      return orders.where((o) => o.rejectedBy == null || !o.rejectedBy!.contains(riderId)).toList();
    });
  }

  /// Reject/Decline an order request
  Future<void> rejectOrder(String orderId, String riderId) async {
    await _db.collection('orders').doc(orderId).update({
      'rejectedBy': FieldValue.arrayUnion([riderId]),
    });
  }

  /// Update order status and handle post-delivery logic (stock, order counts)
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final orderDoc = await _db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;
    
    final order = OrderModel.fromFirestore(orderDoc);
    final batch = _db.batch();

    // 1. Update Order Status
    final Map<String, dynamic> statusData = {'status': status.name};
    if (status == OrderStatus.delivered) {
      statusData['deliveredAt'] = FieldValue.serverTimestamp();
    }
    batch.update(_db.collection('orders').doc(orderId), statusData);

    // 2. Handle Logic when order is DELIVERED
    if (status == OrderStatus.delivered) {
      // Update Shop stats
      batch.update(_db.collection('shops').doc(order.shopId), {
        'activeOrders': FieldValue.increment(-1),
      });

      // Update Products (Stock Decrease & Order Count Increase)
      for (var item in order.items) {
        final productId = item['productId'];
        final quantity = (item['quantity'] ?? 1) as int;
        
        batch.update(_db.collection('products').doc(productId), {
          'stock': FieldValue.increment(-quantity),
          'soldQuantity': FieldValue.increment(quantity),
          'orderCount': FieldValue.increment(1), // Total times this product was ordered
        });
      }
    }

    // 3. Handle Logic when order is CANCELLED/REJECTED (if it was previously active)
    if (status == OrderStatus.cancelled || status == OrderStatus.rejected) {
      if (order.status != OrderStatus.delivered && 
          order.status != OrderStatus.cancelled && 
          order.status != OrderStatus.rejected) {
        batch.update(_db.collection('shops').doc(order.shopId), {
          'activeOrders': FieldValue.increment(-1),
        });
      }
    }

    await batch.commit();
  }

  /// Get active tasks for a rider
  Stream<List<OrderModel>> getActiveRiderOrders(String riderId) {
    return _db
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
      final all = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      return all.where((o) => 
        o.status != OrderStatus.delivered && 
        o.status != OrderStatus.cancelled && 
        o.status != OrderStatus.rejected
      ).toList();
    });
  }

  /// Get total history for a rider
  Stream<List<OrderModel>> getRiderHistory(String riderId) {
    return _db
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      // Sort in-memory to avoid index requirement
      orders.sort((a, b) => (b.deliveredAt ?? b.createdAt).compareTo(a.deliveredAt ?? a.createdAt));
      return orders;
    });
  }

  /// Get today's history for earnings calculation
  Stream<List<OrderModel>> getTodayRiderHistory(String riderId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _db
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .where((o) => o.deliveredAt != null && o.deliveredAt!.isAfter(startOfDay))
          .toList();
      // Sort in-memory
      orders.sort((a, b) => b.deliveredAt!.compareTo(a.deliveredAt!));
      return orders;
    });
  }

  /// Get stream of reviews for a specific rider
  Stream<List<ReviewModel>> getRiderReviews(String riderId) {
    return _db
        .collection('rider_reviews')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
          // Sort in-memory by date descending
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _db.collection('users').doc(userId).collection('notifications').doc(notificationId).update({'isRead': true});
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _db.collection('users').doc(userId).collection('notifications').doc(notificationId).delete();
  }

  /// Upload document
  Future<void> uploadDocument(String uid, String type, String url) async {
    await _db.collection('users').doc(uid).update({
      'documents.$type': 'pending', // Mark as pending review
      'documentUrls.$type': url,
    });
  }

  /// Submit all uploaded documents for Admin approval
  Future<void> submitDocumentsForApproval(String uid, String name, Map<String, String> documentUrls) async {
    // 1. Create a verification request in approvals collection
    await _db.collection('approvals').add({
      'applicantId': uid,
      'applicantName': name,
      'type': 'riderVerification',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'details': {
        'documentUrls': documentUrls,
        'message': 'Rider has uploaded new documents for verification.',
      },
    });

    // 2. Mark user status as pending_verification if not already
    await _db.collection('users').doc(uid).update({
      'verificationStatus': 'pending',
    });
  }

  /// Update Rider Profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Get payout history for a rider
  Stream<List<PayoutModel>> getPayoutHistory(String riderId) {
    return _db.collection('payouts')
        .where('userId', isEqualTo: riderId)
        .snapshots()
        .map((s) {
          final payouts = s.docs.map((doc) => PayoutModel.fromFirestore(doc)).toList();
          payouts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return payouts;
        });
  }

  /// Request a withdrawal
  Future<void> requestWithdrawal(String riderId, double amount) async {
    final userDoc = await _db.collection('users').doc(riderId).get();
    final earnings = (userDoc.data()?['totalEarnings'] ?? 0.0).toDouble();

    if (amount > earnings) {
      throw Exception('Insufficient balance');
    }

    // 1. Create payout request
    await _db.collection('payouts').add({
      'userId': riderId,
      'userName': userDoc.data()?['name'] ?? 'Rider',
      'userType': 'rider',
      'amount': amount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'bankDetails': userDoc.data()?['bankDetails'] ?? {},
    });

    // 2. Deduct from totalEarnings immediately (escrow)
    await _db.collection('users').doc(riderId).update({
      'totalEarnings': FieldValue.increment(-amount),
    });
  }
}
