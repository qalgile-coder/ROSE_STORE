import 'package:cloud_firestore/cloud_firestore.dart';

enum PayoutStatus {
  pending,
  approved,
  rejected,
  paid
}

enum PayoutUserType {
  vendor,
  rider
}

class PayoutModel {
  final String id;
  final String userId;
  final String userName;
  final PayoutUserType userType;
  final double amount;
  final PayoutStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? paymentMethod;
  final String? transactionId;
  final Map<String, dynamic>? bankDetails;

  PayoutModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.paymentMethod,
    this.transactionId,
    this.bankDetails,
  });

  factory PayoutModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PayoutModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userType: data['userType'] == 'vendor' ? PayoutUserType.vendor : PayoutUserType.rider,
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null ? (data['processedAt'] as Timestamp).toDate() : null,
      paymentMethod: data['paymentMethod'],
      transactionId: data['transactionId'],
      bankDetails: data['bankDetails'],
    );
  }

  static PayoutStatus _parseStatus(String? status) {
    return PayoutStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PayoutStatus.pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userType': userType.name,
      'amount': amount,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'bankDetails': bankDetails,
    };
  }
}
