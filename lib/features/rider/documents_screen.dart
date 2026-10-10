import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(userModelProvider).asData?.value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final docs = user.documents ?? {};
    final urls = user.documentUrls ?? {};
    
    // Check if all essential docs are uploaded
    final bool canSubmit = docs['cnic_front'] == 'pending' || 
                          docs['cnic_back'] == 'pending' || 
                          docs['license'] == 'pending';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rider Verification', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/rider');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'GOVERNMENT COMPLIANCE',
                  style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep your documents up to date to maintain your active verified status.',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500, height: 1.5),
                ),
                const SizedBox(height: 32),
                _DocumentCard(
                  title: 'CNIC Front Face',
                  status: docs['cnic_front'] ?? 'not_uploaded',
                  colorScheme: colorScheme,
                  onUpload: () => _handleUpload(context, ref, user.uid, 'cnic_front'),
                ),
                _DocumentCard(
                  title: 'CNIC Rear Face',
                  status: docs['cnic_back'] ?? 'not_uploaded',
                  colorScheme: colorScheme,
                  onUpload: () => _handleUpload(context, ref, user.uid, 'cnic_back'),
                ),
                _DocumentCard(
                  title: 'Driving License',
                  status: docs['license'] ?? 'not_uploaded',
                  colorScheme: colorScheme,
                  onUpload: () => _handleUpload(context, ref, user.uid, 'license'),
                ),
                _DocumentCard(
                  title: 'Vehicle Registration',
                  status: docs['registration'] ?? 'not_uploaded',
                  colorScheme: colorScheme,
                  onUpload: () => _handleUpload(context, ref, user.uid, 'registration'),
                ),
                _DocumentCard(
                  title: 'Personal Insurance',
                  status: docs['insurance'] ?? 'not_uploaded',
                  colorScheme: colorScheme,
                  onUpload: () => _handleUpload(context, ref, user.uid, 'insurance'),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Documents are reviewed within 24-48 business hours.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Professional Submission Action
          if (canSubmit && user.verificationStatus != VerificationStatus.pending)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
              ),
              child: ElevatedButton(
                onPressed: () async {
                   final Map<String, String> docUrls = {};
                   urls.forEach((k, v) => docUrls[k] = v.toString());
                   
                   await ref.read(riderServiceProvider).submitDocumentsForApproval(user.uid, user.name, docUrls);
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Verification request submitted to Admin!'), backgroundColor: AppColors.success),
                     );
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('SUBMIT FOR REVIEW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            
          if (user.verificationStatus == VerificationStatus.pending)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Text(
                'YOUR DOCUMENTS ARE UNDER REVIEW',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
              ),
            ),
        ],
      ),
    );
  }

  void _handleUpload(BuildContext context, WidgetRef ref, String uid, String type) async {
    final url = await ref.read(uploadServiceProvider).pickAndUploadImage(
      context: context,
      folder: 'rider_documents',
    );

    if (url != null) {
      await ref.read(riderServiceProvider).uploadDocument(uid, type, url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded for review'), backgroundColor: AppColors.success),
        );
      }
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String status;
  final ColorScheme colorScheme;
  final VoidCallback onUpload;

  const _DocumentCard({required this.title, required this.status, required this.colorScheme, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: status == 'rejected' || status == 'not_uploaded' ? onUpload : null,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        _getStatusText(status).toUpperCase(),
                        style: TextStyle(color: _getStatusColor(status), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                if (status == 'rejected' || status == 'not_uploaded')
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.file_upload_outlined, color: colorScheme.primary, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.verified_rounded;
      case 'pending': return Icons.timer_rounded;
      case 'rejected': return Icons.error_outline_rounded;
      default: return Icons.upload_file_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'pending': return Colors.orange;
      case 'rejected': return AppColors.error;
      default: return colorScheme.onSurface.withValues(alpha: 0.2);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved': return 'Verified';
      case 'pending': return 'Pending Review';
      case 'rejected': return 'Rejected - Re-upload';
      default: return 'Action Required';
    }
  }
}
