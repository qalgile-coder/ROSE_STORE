import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String customerName;
  final double rating;
  final String review;
  final String orderId;
  final String shopId;
  final String? riderId;
  final List<Map<String, dynamic>> productRatings;
  final DateTime createdAt;
  final String? reply;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.review,
    required this.orderId,
    this.shopId = '',
    this.riderId,
    this.productRatings = const [],
    required this.createdAt,
    this.reply,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      customerName: data['customerName'] ?? 'Anonymous',
      rating: (data['rating'] ?? 0.0).toDouble(),
      review: data['review'] ?? '',
      orderId: data['orderId'] ?? '',
      shopId: data['shopId'] ?? '',
      riderId: data['riderId'],
      productRatings: data['productRatings'] != null
          ? List<Map<String, dynamic>>.from(data['productRatings'])
          : [],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      reply: data['reply'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'rating': rating,
      'review': review,
      'orderId': orderId,
      'shopId': shopId,
      'riderId': riderId,
      'productRatings': productRatings,
      'createdAt': FieldValue.serverTimestamp(),
      'reply': reply,
    };
  }
}