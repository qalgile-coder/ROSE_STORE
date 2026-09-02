import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String customerName;
  final double rating;
  final String review;
  final String orderId;
  final DateTime createdAt;
  final String? reply;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.review,
    required this.orderId,
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reply: data['reply'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'rating': rating,
      'review': review,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
      'reply': reply,
    };
  }
}
