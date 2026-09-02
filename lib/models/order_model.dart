import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,      // Customer placed order
  preparing,    // Vendor accepted and preparing
  confirmed,    // Vendor marked as ready for pickup (previously confirmed)
  accepted,     // Rider accepted
  reachedVendor,
  pickedUp,
  outForDelivery,
  delivered,
  cancelled,
  rejected      // Vendor rejected
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vendorId;
  final String shopId;
  final String shopName;
  final String shopImageUrl;
  final String vendorPhone;
  final String? riderId;
  final OrderStatus status;
  final double totalAmount;
  final double deliveryFee;
  final String pickupAddress;
  final String deliveryAddress;
  final GeoPoint? pickupLocation;
  final GeoPoint? deliveryLocation;
  final List<dynamic> items;
  final String paymentMethod;
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? deliveryOtp;
  final List<String>? rejectedBy;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vendorId,
    required this.shopId,
    required this.shopName,
    required this.shopImageUrl,
    required this.vendorPhone,
    this.riderId,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.pickupLocation,
    this.deliveryLocation,
    required this.items,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.deliveryOtp,
    this.rejectedBy,
    required this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      vendorId: data['vendorId'] ?? '',
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      shopImageUrl: data['shopImageUrl'] ?? '',
      vendorPhone: data['vendorPhone'] ?? '',
      riderId: data['riderId'],
      status: _parseStatus(data['status']),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      pickupAddress: data['pickupAddress'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      pickupLocation: data['pickupLocation'],
      deliveryLocation: data['deliveryLocation'],
      items: data['items'] ?? [],
      paymentMethod: data['paymentMethod'] ?? 'Cash on Delivery',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      deliveryOtp: data['deliveryOtp'],
      rejectedBy: data['rejectedBy'] != null ? List<String>.from(data['rejectedBy']) : null,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      deliveredAt: data['deliveredAt'] != null ? (data['deliveredAt'] as Timestamp).toDate() : null,
    );
  }

  static OrderStatus _parseStatus(String? status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vendorId': vendorId,
      'shopId': shopId,
      'shopName': shopName,
      'shopImageUrl': shopImageUrl,
      'vendorPhone': vendorPhone,
      'riderId': riderId,
      'status': status.name,
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'pickupLocation': pickupLocation,
      'deliveryLocation': deliveryLocation,
      'items': items,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'deliveryOtp': deliveryOtp,
      'rejectedBy': rejectedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    };
  }
}
