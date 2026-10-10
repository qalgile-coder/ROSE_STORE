import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_report_model.dart';
import '../models/support_ticket_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class EmergencyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications;

  EmergencyService(this._notifications);

  /// Submit an emergency report
  Future<String> submitReport(EmergencyReportModel report) async {
    final docRef = await _db.collection('emergency_reports').add(report.toMap());
    
    // 1. Create Initial Timeline Event
    await addTimelineEvent(docRef.id, EmergencyTimelineEvent(
      id: '',
      title: 'Report Submitted',
      description: 'The emergency report has been successfully received by our critical response team.',
      timestamp: DateTime.now(),
    ));

    // 2. Notify Super Admin Immediately (High Priority)
    await _db.collection('admin_notifications').add({
      'title': '🚨 Emergency Report',
      'message': 'Critical: ${report.customerName} reported ${report.category} for Order #${report.orderId?.substring(0, 5)}',
      'type': 'emergency',
      'priority': 'critical',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'data': {
        'reportId': docRef.id,
        'orderId': report.orderId,
      },
    });

    // Send Push to Admins
    _notifications.notifyRole(
      role: UserRole.superAdmin, 
      title: '🚨 EMERGENCY REPORT', 
      body: 'Critical: ${report.customerName} reported ${report.category}',
    );

    // 3. Notify Vendor/Rider if involved (Professional alert)
    if (report.riderId != null) {
      _notifications.notifyUser(
        userId: report.riderId!, 
        title: 'Safety Alert', 
        body: 'A report regarding your recent delivery is under investigation.',
      );
    }

    if (report.vendorId != null) {
      _notifications.notifyUser(
        userId: report.vendorId!, 
        title: 'Critical Store Update', 
        body: 'Our compliance team is reviewing a recent order from your shop.',
      );
    }

    return docRef.id;
  }

  /// Add event to emergency timeline
  Future<void> addTimelineEvent(String reportId, EmergencyTimelineEvent event) async {
    await _db
        .collection('emergency_reports')
        .doc(reportId)
        .collection('emergency_timeline')
        .add(event.toMap());
    
    await _db.collection('emergency_reports').doc(reportId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get stream of emergency reports for a customer
  Stream<List<EmergencyReportModel>> getCustomerReports(String customerId) {
    return _db
        .collection('emergency_reports')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs.map((doc) => EmergencyReportModel.fromFirestore(doc)).toList();
          reports.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return reports;
        });
  }

  /// Get stream of messages for emergency
  Stream<List<SupportMessageModel>> getEmergencyMessages(String reportId) {
    return _db
        .collection('emergency_messages')
        .where('reportId', isEqualTo: reportId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessageModel.fromFirestore(doc))
            .toList());
  }

  /// Send message in emergency chat
  Future<void> sendEmergencyMessage(String reportId, SupportMessageModel message) async {
    await _db.collection('emergency_messages').add({
      ...message.toMap(),
      'reportId': reportId,
    });
    
    await _db.collection('emergency_reports').doc(reportId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get timeline stream
  Stream<List<EmergencyTimelineEvent>> getTimeline(String reportId) {
    return _db
        .collection('emergency_reports')
        .doc(reportId)
        .collection('emergency_timeline')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyTimelineEvent.fromFirestore(doc))
            .toList());
  }

  /// Get single report stream
  Stream<EmergencyReportModel?> getReportStream(String reportId) {
    return _db.collection('emergency_reports').doc(reportId).snapshots().map((doc) {
      if (doc.exists) return EmergencyReportModel.fromFirestore(doc);
      return null;
    });
  }
}
