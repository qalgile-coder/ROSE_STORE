import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications;

  OrderService(this._notifications);

  /// Central method to update order status and trigger all side effects
  Future<void> updateStatus(String orderId, OrderStatus newStatus, {String? riderId, String? reason}) async {
    final orderRef = _db.collection('orders').doc(orderId);
    
    // 1. Fetch current order data
    final orderDoc = await orderRef.get();
    if (!orderDoc.exists) return;
    final order = OrderModel.fromFirestore(orderDoc);

    WriteBatch batch = _db.batch();

    // 2. Prepare Update Data
    Map<String, dynamic> updateData = {'status': newStatus.name};
    
    // HEALER: If order lacks OTP when accepted, generate one now
    if (newStatus == OrderStatus.accepted) {
      updateData['riderId'] = riderId;
      if (order.deliveryOtp == null || order.deliveryOtp!.isEmpty) {
        final newOtp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
        updateData['deliveryOtp'] = newOtp;
      }
    }
    
    if (newStatus == OrderStatus.delivered) {
      updateData['deliveredAt'] = FieldValue.serverTimestamp();
      updateData['paymentStatus'] = 'paid'; // Mark as paid upon delivery for COD
      
      // 3. Side Effect: Update Rider Earnings
      if (order.riderId != null) {
        final riderRef = _db.collection('users').doc(order.riderId);
        batch.update(riderRef, {
          'totalDeliveries': FieldValue.increment(1),
          'totalEarnings': FieldValue.increment(order.deliveryFee),
        });
      }

      // 4. Side Effect: Update Vendor Sales & Shop Revenue
      final vendorRef = _db.collection('users').doc(order.vendorId);
      batch.update(vendorRef, {
        'totalEarnings': FieldValue.increment(order.totalAmount - order.deliveryFee),
      });

      // Update Shop Analytics (Total Sales Count)
      final shopRef = _db.collection('shops').doc(order.shopId);
      batch.update(shopRef, {
        'totalSales': FieldValue.increment(1),
        'revenue': FieldValue.increment(order.totalAmount - order.deliveryFee),
      });

      // 4.5 Side Effect: Update Product Stats (Stock, Sold, Order Count)
      for (var item in order.items) {
        final productId = item['productId'];
        if (productId != null) {
          final prodRef = _db.collection('products').doc(productId);
          final quantity = (item['quantity'] ?? 1) as int;
          batch.update(prodRef, {
            'stock': FieldValue.increment(-quantity),
            'soldQuantity': FieldValue.increment(quantity),
            'orderCount': FieldValue.increment(1),
          });
        }
      }
    }

    // 5. Create Notifications based on Phase
    _createNotifications(batch, order, newStatus);

    // 6. Commit Batch
    batch.update(orderRef, updateData);
    
    try {
      await batch.commit();
      // 7. Trigger Push Notifications after successful DB update
      _triggerPushNotifications(order, newStatus);
    } catch (e) {
      debugPrint("CRITICAL: Order side-effects failed: $e");
      // Fallback: Try updating only the order status if the batch fails due to permissions on other collections
      await orderRef.update(updateData);
    }
  }

  void _createNotifications(WriteBatch batch, OrderModel order, OrderStatus status) {
    // Customer Notifications
    final customerNotifRef = _db.collection('users').doc(order.customerId).collection('notifications').doc();
    String customerTitle = '';
    String customerMsg = '';

    switch (status) {
      case OrderStatus.preparing:
        customerTitle = 'Order Accepted';
        customerMsg = 'Your order from ${order.shopName} is being prepared.';
        break;
      case OrderStatus.confirmed:
        customerTitle = 'Ready for Pickup';
        customerMsg = 'Your order is packed and waiting for a rider.';
        break;
      case OrderStatus.accepted:
        customerTitle = 'Rider Assigned';
        customerMsg = 'A rider has been assigned to your order. Give OTP ${order.deliveryOtp} to the rider upon arrival.';
        break;
      case OrderStatus.pickedUp:
        customerTitle = 'Out for Delivery';
        customerMsg = 'Your order has been picked up and is on the way!';
        break;
      case OrderStatus.delivered:
        customerTitle = 'Order Delivered';
        customerMsg = 'Enjoy your purchase! Please rate your experience.';
        break;
      case OrderStatus.cancelled:
        customerTitle = 'Order Cancelled';
        customerMsg = 'Your order has been cancelled by the vendor.';
        break;
      default: break;
    }

    if (customerTitle.isNotEmpty) {
      batch.set(customerNotifRef, {
        'title': customerTitle,
        'message': customerMsg,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'order_status',
        'orderId': order.id,
      });
    }

    // Vendor Notifications (for things like Rider Assigned)
    if (status == OrderStatus.accepted) {
      final vendorNotifRef = _db.collection('users').doc(order.vendorId).collection('notifications').doc();
      batch.set(vendorNotifRef, {
        'title': 'Rider Assigned',
        'message': 'A rider has accepted the delivery for Order #${order.id.substring(0, 5)}',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'orderId': order.id,
      });
    }

    // Admin Notifications for key events
    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      final adminNotifRef = _db.collection('admin_notifications').doc();
      batch.set(adminNotifRef, {
        'title': status == OrderStatus.delivered ? 'Sale Completed' : 'Order Cancelled',
        'message': 'Order #${order.id.substring(0, 5)} from ${order.shopName} was ${status.name}.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'orderId': order.id,
      });
    }
  }

  void _triggerPushNotifications(OrderModel order, OrderStatus status) {
    String title = '';
    String body = '';

    // Customer Push
    switch (status) {
      case OrderStatus.preparing:
        title = 'Order Accepted';
        body = 'Your order from ${order.shopName} is being prepared.';
        break;
      case OrderStatus.confirmed:
        title = 'Ready for Pickup';
        body = 'Your order is packed and waiting for a rider.';
        break;
      case OrderStatus.accepted:
        title = 'Rider Assigned';
        body = 'A rider is coming to pick up your order. Your OTP is ${order.deliveryOtp}';
        break;
      case OrderStatus.pickedUp:
        title = 'Out for Delivery';
        body = 'Your order from ${order.shopName} is on its way!';
        break;
      case OrderStatus.delivered:
        title = 'Enjoy your meal!';
        body = 'Your order #${order.id.substring(0, 5)} has been delivered.';
        break;
      case OrderStatus.cancelled:
        title = 'Order Cancelled';
        body = 'Order #${order.id.substring(0, 5)} was cancelled by the vendor.';
        break;
      default: break;
    }

    if (title.isNotEmpty) {
      _notifications.notifyUser(userId: order.customerId, title: title, body: body, data: {'orderId': order.id});
    }

    // Vendor Push (e.g. when order is placed - handled elsewhere, or rider assigned)
    if (status == OrderStatus.accepted) {
      _notifications.notifyUser(
        userId: order.vendorId, 
        title: 'Rider Assigned', 
        body: 'Rider is on the way to pick up Order #${order.id.substring(0, 5)}',
        data: {'orderId': order.id},
      );
    }

    // Admin Push
    if (status == OrderStatus.delivered) {
      _notifications.notifyRole(
        role: UserRole.superAdmin, 
        title: 'Platform Sale', 
        body: 'Rs ${order.totalAmount} collected from ${order.shopName}',
      );
    }
  }
}
