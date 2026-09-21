import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalType {
  vendorRegistration,
  riderRegistration,
  shopApproval,
  riderVerification
}

enum ApprovalStatus {
  pending,
  approved,
  rejected
}

class ApprovalModel {
  final String id;
  final String applicantId;
  final String applicantName;
  final ApprovalType type;
  final ApprovalStatus status;
  final DateTime createdAt;
  final Map<String, dynamic> details; // email, phone, shopName, vehicleInfo, docsUrls etc.

  ApprovalModel({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.details,
  });

  factory ApprovalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ApprovalModel(
      id: doc.id,
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      type: _parseType(data['type']),
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      details: data['details'] ?? {},
    );
  }

  static ApprovalType _parseType(String? type) {
    return ApprovalType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ApprovalType.vendorRegistration,
    );
  }

  static ApprovalStatus _parseStatus(String? status) {
    return ApprovalStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ApprovalStatus.pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicantId': applicantId,
      'applicantName': applicantName,
      'type': type.name,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'details': details,
    };
  }
}
