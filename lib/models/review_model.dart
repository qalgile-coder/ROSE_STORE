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

  /// إنشاء كائن ReviewModel من مستند Firestore مع حماية تامة ضد أخطاء أنواع البيانات
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return ReviewModel(
      id: doc.id,
      customerName: data['customerName'] as String? ?? 'Anonymous',
      rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      review: data['review'] as String? ?? '',
      orderId: data['orderId'] as String? ?? '',
      shopId: data['shopId'] as String? ?? '',
      riderId: data['riderId'] as String?,
      productRatings: data['productRatings'] != null
          ? List<Map<String, dynamic>>.from(data['productRatings'])
          : [],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      reply: data['reply'] as String?,
    );
  }

  /// تحويل كائن البيانات إلى Map لحفظه في Firestore
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

  /// دالة مساعدة لتحديث بعض حقول الكائن بسهولة عند الحاجة
  ReviewModel copyWith({
    String? id,
    String? customerName,
    double? rating,
    String? review,
    String? orderId,
    String? shopId,
    String? riderId,
    List<Map<String, dynamic>>? productRatings,
    DateTime? createdAt,
    String? reply,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      orderId: orderId ?? this.orderId,
      shopId: shopId ?? this.shopId,
      riderId: riderId ?? this.riderId,
      productRatings: productRatings ?? this.productRatings,
      createdAt: createdAt ?? this.createdAt,
      reply: reply ?? this.reply,
    );
  }
}