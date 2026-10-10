import 'package:cloud_firestore/cloud_firestore.dart';

enum EmergencyStatus {
  submitted,
  underReview,
  investigating,
  waitingForCustomer,
  resolved,
  rejected,
  escalated
}

class EmergencyReportModel {
  final String id;
  final String customerId;
  final String customerName;
  final String category;
  final String description;
  final String? orderId;
  final String? vendorId;
  final String? riderId;
  final GeoPoint? location;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? screenshotUrl;
  final String contactNumber;
  final String priority; // Critical
  final EmergencyStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyReportModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.category,
    required this.description,
    this.orderId,
    this.vendorId,
    this.riderId,
    this.location,
    this.imageUrls = const [],
    this.videoUrl,
    this.screenshotUrl,
    required this.contactNumber,
    this.priority = 'Critical',
    this.status = EmergencyStatus.submitted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyReportModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Customer',
      category: data['category'] ?? 'Other',
      description: data['description'] ?? '',
      orderId: data['orderId'],
      vendorId: data['vendorId'],
      riderId: data['riderId'],
      location: data['location'],
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [],
      videoUrl: data['videoUrl'],
      screenshotUrl: data['screenshotUrl'],
      contactNumber: data['contactNumber'] ?? '',
      priority: data['priority'] ?? 'Critical',
      status: EmergencyStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EmergencyStatus.submitted,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'category': category,
      'description': description,
      'orderId': orderId,
      'vendorId': vendorId,
      'riderId': riderId,
      'location': location,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'screenshotUrl': screenshotUrl,
      'contactNumber': contactNumber,
      'priority': priority,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class EmergencyTimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? actionBy;

  EmergencyTimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.actionBy,
  });

  factory EmergencyTimelineEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyTimelineEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actionBy: data['actionBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'actionBy': actionBy,
    };
  }
}
