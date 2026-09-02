import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String offerType; // e.g., 'percentage', 'free_delivery', 'fixed'
  final double value;
  final String? couponCode;
  final List<String> applicableShopIds;
  final List<String> applicableProductIds;
  final DateTime expiryDate;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.offerType,
    required this.value,
    this.couponCode,
    this.applicableShopIds = const [],
    this.applicableProductIds = const [],
    required this.expiryDate,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      offerType: data['offerType'] ?? 'percentage',
      value: (data['value'] ?? 0.0).toDouble(),
      couponCode: data['couponCode'],
      applicableShopIds: List<String>.from(data['applicableShopIds'] ?? []),
      applicableProductIds: List<String>.from(data['applicableProductIds'] ?? []),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'offerType': offerType,
      'value': value,
      'couponCode': couponCode,
      'applicableShopIds': applicableShopIds,
      'applicableProductIds': applicableProductIds,
      'expiryDate': Timestamp.fromDate(expiryDate),
    };
  }
}
