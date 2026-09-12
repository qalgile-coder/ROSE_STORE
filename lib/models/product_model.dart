import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String vendorId;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final String currency; // حقل العملة (ج.س، ج.م، ر.س)
  final double discount;
  final int stock;
  final int soldQuantity;
  final String unit;
  final List<String> imageUrls; // قائمة الصور المتعددة
  final String imageUrl; // للتوافق العكسي مع الكود القديم
  final String category;
  final String brand;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final int orderCount;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.vendorId,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'ج.س',
    this.discount = 0.0,
    required this.stock,
    this.soldQuantity = 0,
    required this.unit,
    this.imageUrls = const [],
    this.imageUrl = '',
    required this.category,
    this.brand = 'Generic',
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.orderCount = 0,
    required this.createdAt,
  });

  ProductModel copyWith({
    String? id,
    String? vendorId,
    String? shopId,
    String? name,
    String? description,
    double? price,
    String? currency,
    double? discount,
    int? stock,
    int? soldQuantity,
    String? unit,
    List<String>? imageUrls,
    String? imageUrl,
    String? category,
    String? brand,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    int? orderCount,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      discount: discount ?? this.discount,
      stock: stock ?? this.stock,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      orderCount: orderCount ?? this.orderCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // التعامل مع قائمة الصور أو الصورة المفردة القديمة
    List<String> parsedImages = [];
    if (data['imageUrls'] != null) {
      parsedImages = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      parsedImages = [data['imageUrl']];
    }

    return ProductModel(
      id: doc.id,
      vendorId: data['vendorId'] ?? '',
      shopId: data['shopId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'ج.س',
      discount: (data['discount'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      soldQuantity: data['soldQuantity'] ?? 0,
      unit: data['unit'] ?? 'pcs',
      imageUrls: parsedImages,
      imageUrl: parsedImages.isNotEmpty ? parsedImages.first : (data['imageUrl'] ?? ''),
      category: data['category'] ?? 'General',
      brand: data['brand'] ?? 'Generic',
      isAvailable: data['isAvailable'] ?? true,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      orderCount: data['orderCount'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()) 
          : DateTime.now(),
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String documentId) {
    List<String> parsedImages = [];
    if (map['imageUrls'] != null) {
      parsedImages = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] != null && map['imageUrl'].toString().isNotEmpty) {
      parsedImages = [map['imageUrl']];
    }

    return ProductModel(
      id: documentId,
      vendorId: map['vendorId'] ?? '',
      shopId: map['shopId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'ج.س',
      discount: (map['discount'] ?? 0.0).toDouble(),
      stock: map['stock'] ?? 0,
      soldQuantity: map['soldQuantity'] ?? 0,
      unit: map['unit'] ?? 'pcs',
      imageUrls: parsedImages,
      imageUrl: parsedImages.isNotEmpty ? parsedImages.first : (map['imageUrl'] ?? ''),
      category: map['category'] ?? 'General',
      brand: map['brand'] ?? 'Generic',
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      orderCount: map['orderCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'shopId': shopId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'discount': discount,
      'stock': stock,
      'soldQuantity': soldQuantity,
      'unit': unit,
      'imageUrls': imageUrls,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : imageUrl, // حفظ أول صورة في الحقل القديم للاحتياط
      'category': category,
      'brand': brand,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'orderCount': orderCount,
      'createdAt': createdAt,
    };
  }
}