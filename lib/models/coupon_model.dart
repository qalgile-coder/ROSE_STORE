import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String shopId;
  final String code;
  final double discountPercentage;
  final double fixedDiscount;
  final DateTime expiryDate;
  final double minOrderAmount;
  final String description;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.shopId,
    required this.code,
    this.discountPercentage = 0.0,
    this.fixedDiscount = 0.0,
    required this.expiryDate,
    this.minOrderAmount = 0.0,
    this.description = '',
    this.isActive = true,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      code: data['code'] ?? '',
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      fixedDiscount: (data['fixedDiscount'] ?? 0.0).toDouble(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      minOrderAmount: (data['minOrderAmount'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'code': code,
      'discountPercentage': discountPercentage,
      'fixedDiscount': fixedDiscount,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'minOrderAmount': minOrderAmount,
      'description': description,
      'isActive': isActive,
    };
  }
}
