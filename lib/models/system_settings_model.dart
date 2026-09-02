import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsModel {
  final double deliveryCharge;
  final double taxPercentage;
  final double platformCommission;
  final bool maintenanceMode;
  final String appVersion;
  final String supportEmail;
  final String supportPhone;

  SystemSettingsModel({
    required this.deliveryCharge,
    required this.taxPercentage,
    required this.platformCommission,
    this.maintenanceMode = false,
    required this.appVersion,
    required this.supportEmail,
    required this.supportPhone,
  });

  factory SystemSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SystemSettingsModel(
      deliveryCharge: (data['deliveryCharge'] ?? 0.0).toDouble(),
      taxPercentage: (data['taxPercentage'] ?? 0.0).toDouble(),
      platformCommission: (data['platformCommission'] ?? 15.0).toDouble(),
      maintenanceMode: data['maintenanceMode'] ?? false,
      appVersion: data['appVersion'] ?? '1.0.0',
      supportEmail: data['supportEmail'] ?? 'support@zenmartpro.com',
      supportPhone: data['supportPhone'] ?? '+920000000000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryCharge': deliveryCharge,
      'taxPercentage': taxPercentage,
      'platformCommission': platformCommission,
      'maintenanceMode': maintenanceMode,
      'appVersion': appVersion,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
    };
  }
}
