import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  superAdmin,
  vendor,
  customer,
  rider,
  unknown
}

enum VerificationStatus {
  pending,
  verified,
  rejected
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? shopId;
  final String status;
  final DateTime createdAt;
  final String? profilePicture;
  
  // Rider & Vendor specific
  final bool isOnline;
  final String? vehicleInfo;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleImage;
  final String? licenseNumber;
  final String? cnic;
  final String? address;
  final double rating;
  final int totalDeliveries;
  final double totalEarnings;
  final VerificationStatus verificationStatus;
  final Map<String, String>? documents; // docType -> status (uploaded, pending, approved, rejected)
  final Map<String, String>? documentUrls; // docType -> url
  final Map<String, dynamic>? bankDetails;
  final String? fcmToken;
  final String? referralCode;
  final String? referredBy;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.shopId,
    required this.status,
    required this.createdAt,
    this.profilePicture,
    this.isOnline = false,
    this.vehicleInfo,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleImage,
    this.licenseNumber,
    this.cnic,
    this.address,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
    this.verificationStatus = VerificationStatus.pending,
    this.documents,
    this.documentUrls,
    this.bankDetails,
    this.fcmToken,
    this.referralCode,
    this.referredBy,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: _parseRole(data['role']),
      shopId: data['shopId'],
      status: data['status'] ?? 'active',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      profilePicture: data['profilePicture'],
      isOnline: data['isOnline'] ?? false,
      vehicleInfo: data['vehicleInfo'],
      vehicleBrand: data['vehicleBrand'],
      vehicleModel: data['vehicleModel'],
      vehicleColor: data['vehicleColor'],
      vehicleImage: data['vehicleImage'],
      licenseNumber: data['licenseNumber'],
      cnic: data['cnic'],
      address: data['address'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      verificationStatus: _parseVerificationStatus(data['verificationStatus']),
      documents: data['documents'] != null ? Map<String, String>.from(data['documents']) : null,
      documentUrls: data['documentUrls'] != null ? Map<String, String>.from(data['documentUrls']) : null,
      bankDetails: data['bankDetails'] != null ? Map<String, dynamic>.from(data['bankDetails']) : null,
      fcmToken: data['fcmToken'],
      referralCode: data['referralCode'],
      referredBy: data['referredBy'],
    );
  }

  static VerificationStatus _parseVerificationStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified': return VerificationStatus.verified;
      case 'rejected': return VerificationStatus.rejected;
      default: return VerificationStatus.pending;
    }
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
      case 'admin':
        return UserRole.superAdmin;
      case 'vendor':
        return UserRole.vendor;
      case 'customer':
        return UserRole.customer;
      case 'rider':
        return UserRole.rider;
      default:
        return UserRole.unknown;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_').toLowerCase(),
      'shopId': shopId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'profilePicture': profilePicture,
      'isOnline': isOnline,
      'vehicleInfo': vehicleInfo,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehicleImage': vehicleImage,
      'licenseNumber': licenseNumber,
      'cnic': cnic,
      'address': address,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'verificationStatus': verificationStatus.name,
      'documents': documents,
      'documentUrls': documentUrls,
      'bankDetails': bankDetails,
      'fcmToken': fcmToken,
      'referralCode': referralCode,
      'referredBy': referredBy,
    };
  }
}
