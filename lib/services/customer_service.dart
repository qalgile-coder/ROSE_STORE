import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address_model.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../models/offer_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all active promotional offers
  Stream<List<OfferModel>> getActiveOffers() {
    return _db
        .collection('offers')
        .where('expiryDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OfferModel.fromFirestore(doc))
            .toList());
  }

  /// Get shops in a specific category
  Stream<List<ShopModel>> getCategoryShops(String category) {
    return _db
        .collection('shops')
        .where('status', isEqualTo: 'active')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopModel.fromFirestore(doc))
            .toList());
  }

  /// Get featured shops
  Stream<List<ShopModel>> getFeaturedShops() {
    return _db
        .collection('shops')
        .where('status', isEqualTo: 'active')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopModel.fromFirestore(doc))
            .toList());
  }

  /// Get nearby shops (simple implementation fetching all active for now)
  Stream<List<ShopModel>> getNearbyShops() {
    return _db
        .collection('shops')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopModel.fromFirestore(doc))
            .toList());
  }

  /// Get a single shop by ID
  Stream<ShopModel?> getShopById(String shopId) {
    return _db.collection('shops').doc(shopId).snapshots().map((doc) {
      if (doc.exists) return ShopModel.fromFirestore(doc);
      return null;
    });
  }

  /// Get products of a shop
  Stream<List<ProductModel>> getShopProducts(String shopId) {
    return _db
        .collection('products')
        .where('shopId', isEqualTo: shopId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  /// Place a new order
  Future<String> placeOrder(Map<String, dynamic> orderData) async {
    try {
      final docRef = await _db.collection('orders').add(orderData);
      
      // Notify Vendor of New Order - Wrap in isolated try-catch
      try {
        final vendorId = orderData['vendorId'];
        if (vendorId != null) {
          await _db.collection('users').doc(vendorId).collection('notifications').add({
            'title': 'New Order Received! 🛍️',
            'message': 'Order #${docRef.id.substring(0, 5)} for Rs ${orderData['totalAmount']}',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'orderId': docRef.id,
            'type': 'new_order',
          });
        }
      } catch (e) {
        debugPrint('Non-critical: Vendor notification failed: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('CRITICAL: Firestore order placement failed: $e');
      rethrow;
    }
  }

  /// Get stream of a single order
  Stream<OrderModel?> getOrderStream(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      if (doc.exists) return OrderModel.fromFirestore(doc);
      return null;
    });
  }

  /// Get stream of orders for a specific customer
  Stream<List<OrderModel>> getCustomerOrders(String userId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isDeletedByCustomer'] != true;
          })
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Sort in memory to avoid complex index requirement for combined query
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  /// Hide an order from customer history (Soft delete)
  Future<void> deleteOrderForCustomer(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'isDeletedByCustomer': true,
    });
  }

  /// Get products by multiple IDs (for Offer details)
  Stream<List<ProductModel>> getProductsByIds(List<String> productIds) {
    if (productIds.isEmpty) return Stream.value([]);
    return _db
        .collection('products')
        .where(FieldPath.documentId, whereIn: productIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  /// Get shops by multiple IDs (for Offer details)
  Stream<List<ShopModel>> getShopsByIds(List<String> shopIds) {
    if (shopIds.isEmpty) return Stream.value([]);
    return _db
        .collection('shops')
        .where(FieldPath.documentId, whereIn: shopIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopModel.fromFirestore(doc))
            .toList());
  }

  /// Submit or update a review for an order, shop, rider, and specific products
  Future<void> submitReview({
    required String orderId,
    required String shopId,
    required String? riderId,
    required String customerName,
    required double rating,
    required String review,
    List<Map<String, dynamic>> productRatings = const [],
    double? oldRating,
  }) async {
    final batch = _db.batch();
    
    // 1. Add/Update shop reviews
    final shopReviewRef = _db.collection('shops').doc(shopId).collection('reviews').doc(orderId);
    batch.set(shopReviewRef, {
      'orderId': orderId,
      'customerName': customerName,
      'rating': rating,
      'review': review,
      'updatedAt': FieldValue.serverTimestamp(),
      if (oldRating == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Add/Update rider reviews
    if (riderId != null) {
      final riderReviewRef = _db.collection('rider_reviews').doc(orderId);
      batch.set(riderReviewRef, {
        'orderId': orderId,
        'riderId': riderId,
        'customerName': customerName,
        'rating': rating,
        'review': review,
        'updatedAt': FieldValue.serverTimestamp(),
        if (oldRating == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 3. Add/Update individual product reviews
    for (var prodRate in productRatings) {
      final productId = prodRate['productId'];
      final pRating = (prodRate['rating'] ?? 0.0).toDouble();
      final pReview = prodRate['review'] ?? '';

      final prodReviewRef = _db.collection('product_reviews').doc("${orderId}_$productId");
      batch.set(prodReviewRef, {
        'orderId': orderId,
        'productId': productId,
        'customerName': customerName,
        'rating': pRating,
        'review': pReview,
        'updatedAt': FieldValue.serverTimestamp(),
        if (oldRating == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 4. Update order record to mark as reviewed
    batch.update(_db.collection('orders').doc(orderId), {'isReviewed': true});

    await batch.commit();

    // 5. Update Aggregate Ratings
    if (oldRating != null) {
      // Update logic: Adjust the existing average
      await _updateExistingShopRating(shopId, oldRating, rating);
      if (riderId != null) await _updateExistingRiderRating(riderId, oldRating, rating);
    } else {
      // New review logic
      await _updateShopRating(shopId, rating);
      if (riderId != null) await _updateRiderRating(riderId, rating);
    }
    
    // Note: Product aggregate updates for edits are omitted for brevity in this complex batch.
  }

  Future<void> _updateExistingShopRating(String shopId, double oldRating, double newRating) async {
    final docRef = _db.collection('shops').doc(shopId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      double currentCount = (snapshot.data()?['reviewCount'] ?? 0).toDouble();
      
      // Math: (TotalSum - old + new) / Count
      double newAvg = ((currentRating * currentCount) - oldRating + newRating) / currentCount;
      transaction.update(docRef, {
        'rating': double.parse(newAvg.toStringAsFixed(1)),
      });
    }, maxAttempts: 5);
  }

  Future<void> _updateExistingRiderRating(String riderId, double oldRating, double newRating) async {
    final docRef = _db.collection('users').doc(riderId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      double currentCount = (snapshot.data()?['reviewCount'] ?? 0).toDouble();
      
      double newAvg = ((currentRating * currentCount) - oldRating + newRating) / currentCount;
      transaction.update(docRef, {
        'rating': double.parse(newAvg.toStringAsFixed(1)),
      });
    }, maxAttempts: 5);
  }

  /// Delete a review and update aggregate ratings
  Future<void> deleteReview({
    required String orderId,
    required String shopId,
    required String? riderId,
    required List<String> productIds,
  }) async {
    // 1. Fetch the previous ratings to decrement accurately
    final shopRevDoc = await _db.collection('shops').doc(shopId).collection('reviews').doc(orderId).get();
    if (!shopRevDoc.exists) return;

    final double oldShopRating = (shopRevDoc.data()?['rating'] ?? 0.0).toDouble();
    final batch = _db.batch();

    // 2. Delete review documents
    batch.delete(_db.collection('shops').doc(shopId).collection('reviews').doc(orderId));
    if (riderId != null) {
      batch.delete(_db.collection('rider_reviews').doc(orderId));
    }
    for (final pid in productIds) {
      batch.delete(_db.collection('product_reviews').doc("${orderId}_$pid"));
    }

    // 3. Reset order status
    batch.update(_db.collection('orders').doc(orderId), {'isReviewed': false});

    await batch.commit();

    // 4. Update aggregates (Decrement logic)
    await _decrementShopRating(shopId, oldShopRating);
    if (riderId != null) await _decrementRiderRating(riderId, oldShopRating);
    // Note: Decrementing product ratings would require individual lookups, 
    // for now we'll focus on Shop and Rider which are usually more critical.
  }

  Future<void> _decrementShopRating(String shopId, double ratingToRemove) async {
    final docRef = _db.collection('shops').doc(shopId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      double currentCount = (snapshot.data()?['reviewCount'] ?? 0).toDouble();
      
      if (currentCount <= 1) {
        transaction.update(docRef, {'rating': 0.0, 'reviewCount': 0});
      } else {
        double newAvg = ((currentRating * currentCount) - ratingToRemove) / (currentCount - 1.0);
        transaction.update(docRef, {
          'rating': double.parse(newAvg.toStringAsFixed(1)),
          'reviewCount': (currentCount - 1).toInt(),
        });
      }
    }, maxAttempts: 5);
  }

  Future<void> _decrementRiderRating(String riderId, double ratingToRemove) async {
    final docRef = _db.collection('users').doc(riderId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      double currentCount = (snapshot.data()?['reviewCount'] ?? 0).toDouble();
      
      if (currentCount <= 1) {
        transaction.update(docRef, {'rating': 0.0, 'reviewCount': 0});
      } else {
        double newAvg = ((currentRating * currentCount) - ratingToRemove) / (currentCount - 1.0);
        transaction.update(docRef, {
          'rating': double.parse(newAvg.toStringAsFixed(1)),
          'reviewCount': (currentCount - 1).toInt(),
        });
      }
    }, maxAttempts: 5);
  }

  /// Get the review for a specific order
  Future<ReviewModel?> getOrderReview(String shopId, String orderId) async {
    final doc = await _db.collection('shops').doc(shopId).collection('reviews').doc(orderId).get();
    if (doc.exists) return ReviewModel.fromFirestore(doc);
    return null;
  }

  Future<void> _updateShopRating(String shopId, double newRating) async {
    final docRef = _db.collection('shops').doc(shopId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      double currentCount = (snapshot.data()?['reviewCount'] ?? 0).toDouble();
      
      double avg = ((currentRating * currentCount) + newRating) / (currentCount + 1.0);
      transaction.update(docRef, {
        'rating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': (currentCount + 1).toInt(),
      });
    }, maxAttempts: 5);
  }

  Future<void> _updateProductRating(String productId, double newRating) async {
    final docRef = _db.collection('products').doc(productId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      double currentCount = (snapshot.data()?['reviewCount'] ?? 0).toDouble();
      
      double avg = ((currentRating * currentCount) + newRating) / (currentCount + 1.0);
      transaction.update(docRef, {
        'rating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': (currentCount + 1).toInt(),
      });
    }, maxAttempts: 5);
  }

  Future<void> _updateRiderRating(String riderId, double newRating) async {
    final docRef = _db.collection('users').doc(riderId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      double currentCount = (snapshot.data()?['reviewCount'] ?? 0).toDouble();
      
      double avg = ((currentRating * currentCount) + newRating) / (currentCount + 1.0);
      transaction.update(docRef, {
        'rating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': (currentCount + 1).toInt(),
      });
    }, maxAttempts: 5);
  }

  /// Get reviews for a specific product
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    return _db
        .collection('product_reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  /// Toggle Wishlist item
  Future<void> toggleWishlist(String userId, ProductModel product) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(product.id);
    
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set(product.toMap());
    }
  }

  Stream<List<AddressModel>> getSavedAddresses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AddressModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addAddress(String userId, AddressModel address) async {
    if (address.isDefault) {
      await _clearDefaultAddress(userId);
    }
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .add(address.toMap());
  }

  Future<void> updateAddress(String userId, AddressModel address) async {
    if (address.isDefault) {
      await _clearDefaultAddress(userId);
    }
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(address.id)
        .update(address.toMap());
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    await _clearDefaultAddress(userId);
    await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(addressId)
        .update({'isDefault': true});
  }

  Future<void> _clearDefaultAddress(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }

  /// Search Products
  Stream<List<ProductModel>> searchProducts(String query) {
    return _db
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.category.toLowerCase().contains(query.toLowerCase()) ||
                p.brand.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  /// Search Shops
  Stream<List<ShopModel>> searchShops(String query) {
    return _db
        .collection('shops')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopModel.fromFirestore(doc))
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  /// Get all categories from products
  Stream<List<String>> getAllCategories() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['category'] as String? ?? 'General')
          .toSet()
          .toList();
    });
  }

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
