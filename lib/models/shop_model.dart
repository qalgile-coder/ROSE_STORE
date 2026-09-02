import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String id;
  final String name;
  final String vendorId;
  final String vendorName;
  final String address;
  final GeoPoint? location;
  final String category;
  final String imageUrl;
  final String? bannerImage;
  final String? logoUrl;
  final String? openingHours;
  final double rating;
  final int reviewCount;
  final String status;
  final int activeOrders;
  final bool hasFreeDelivery;
  final bool isOpen;
  final String deliveryTime;
  final double deliveryFee;
  final String phone;
  final String description;
  final bool isFeatured;
  final DateTime createdAt;

  ShopModel({
    required this.id,
    required this.name,
    required this.vendorId,
    required this.vendorName,
    required this.address,
    this.location,
    required this.category,
    required this.imageUrl,
    this.bannerImage,
    this.logoUrl,
    this.openingHours,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.status,
    this.activeOrders = 0,
    this.hasFreeDelivery = false,
    this.isOpen = true,
    this.deliveryTime = '25-35 min',
    this.deliveryFee = 0.0,
    this.phone = '',
    this.description = '',
    this.isFeatured = false,
    required this.createdAt,
  });

  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ShopModel(
      id: doc.id,
      name: data['name'] ?? '',
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? 'Unknown Vendor',
      address: data['address'] ?? 'No Address',
      location: data['location'],
      category: data['category'] ?? 'General',
      imageUrl: data['imageUrl'] ?? data['bannerImage'] ?? '',
      bannerImage: data['bannerImage'] ?? data['imageUrl'],
      logoUrl: data['logoUrl'],
      openingHours: data['openingHours'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      status: data['status'] ?? 'active',
      activeOrders: data['activeOrders'] ?? 0,
      hasFreeDelivery: data['hasFreeDelivery'] ?? false,
      isOpen: data['isOpen'] ?? true,
      deliveryTime: data['deliveryTime'] ?? '25-35 min',
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      phone: data['phone'] ?? '',
      description: data['description'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()) 
          : DateTime.now(),
    );
  }

  factory ShopModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ShopModel(
      id: documentId,
      name: map['name'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? 'Unknown Vendor',
      address: map['address'] ?? 'No Address',
      location: map['location'],
      category: map['category'] ?? 'General',
      imageUrl: map['imageUrl'] ?? map['bannerImage'] ?? '',
      bannerImage: map['bannerImage'] ?? map['imageUrl'],
      logoUrl: map['logoUrl'],
      openingHours: map['openingHours'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      status: map['status'] ?? 'active',
      activeOrders: map['activeOrders'] ?? 0,
      hasFreeDelivery: map['hasFreeDelivery'] ?? false,
      isOpen: map['isOpen'] ?? true,
      deliveryTime: map['deliveryTime'] ?? '25-35 min',
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      phone: map['phone'] ?? '',
      description: map['description'] ?? '',
      isFeatured: map['isFeatured'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'address': address,
      'location': location,
      'category': category,
      'imageUrl': imageUrl,
      'bannerImage': bannerImage,
      'logoUrl': logoUrl,
      'openingHours': openingHours,
      'rating': rating,
      'reviewCount': reviewCount,
      'status': status,
      'activeOrders': activeOrders,
      'hasFreeDelivery': hasFreeDelivery,
      'isOpen': isOpen,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'phone': phone,
      'description': description,
      'isFeatured': isFeatured,
      'createdAt': createdAt,
    };
  }
}