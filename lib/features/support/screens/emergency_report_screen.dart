import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_colors.dart';
import '../../../core/providers.dart';
import '../../../models/user_model.dart';
import '../../../models/order_model.dart';
import '../../../models/emergency_report_model.dart';
import '../../../services/emergency_service.dart';

class EmergencyReportScreen extends ConsumerStatefulWidget {
  const EmergencyReportScreen({super.key});

  @override
  ConsumerState<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends ConsumerState<EmergencyReportScreen> {
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCategory;
  OrderModel? _selectedOrder;
  final List<File> _images = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Unsafe Rider', 'Unsafe Vendor', 'Fraud', 'Wrong Delivery', 
    'Payment Scam', 'Fake Product', 'Harassment', 
    'Threatening Behaviour', 'Emergency Refund', 'Other'
  ];

  @override
  void dispose() {
    _descController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _images.add(File(image.path)));
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null || _descController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userModelProvider).asData?.value;
      
      // 1. Get Location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (_) {}

      // 2. Upload Images
      List<String> imageUrls = [];
      for (var file in _images) {
        final url = await ref.read(uploadServiceProvider).uploadImage(file, folder: 'emergency_reports');
        if (url != null) imageUrls.add(url);
      }

      final report = EmergencyReportModel(
        id: '',
        customerId: user!.uid,
        customerName: user.name,
        category: _selectedCategory!,
        description: _descController.text.trim(),
        orderId: _selectedOrder?.id,
        vendorId: _selectedOrder?.vendorId,
        riderId: _selectedOrder?.riderId,
        location: position != null ? GeoPoint(position.latitude, position.longitude) : null,
        imageUrls: imageUrls,
        contactNumber: _phoneController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(emergencyServiceProvider).submitReport(report);

      if (mounted) {
        context.pop();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Received'),
        content: const Text('Your emergency report has been sent to our critical response team. We will contact you immediately.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackground : AppColors.supportDarkBackground,
      appBar: AppBar(title: const Text('Emergency Assistance'), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningCard(),
            const SizedBox(height: 32),
            _buildLabel('Issue Category *'),
            _buildDropdown(),
            const SizedBox(height: 24),
            _buildLabel('Related Order'),
            _buildOrderPicker(ordersAsync),
            const SizedBox(height: 24),
            _buildLabel('Description *'),
            TextField(controller: _descController, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe the emergency in detail...')),
            const SizedBox(height: 24),
            _buildLabel('Evidence (Images)'),
            _buildImagePicker(),
            const SizedBox(height: 24),
            _buildLabel('Your Contact Number *'),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+92 ...')),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 60)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT CRITICAL REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.3))),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 16),
          Expanded(child: Text('Emergency reports are reviewed immediately. False reports may result in account suspension.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
      decoration: const InputDecoration(hintText: 'Select category'),
    );
  }

  Widget _buildOrderPicker(AsyncValue<List<OrderModel>> ordersAsync) {
    return ordersAsync.when(
      data: (orders) => DropdownButtonFormField<OrderModel>(
        items: orders.map((o) => DropdownMenuItem(value: o, child: Text('${o.shopName} (#${o.id.substring(0, 5)})'))).toList(),
        onChanged: (v) => setState(() => _selectedOrder = v),
        decoration: const InputDecoration(hintText: 'Select involved order'),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error loading orders'),
    );
  }

  Widget _buildImagePicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._images.map((f) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(f, width: 80, height: 80, fit: BoxFit.cover))),
        if (_images.length < 5)
          InkWell(
            onTap: _pickImage,
            child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.3))), child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey)),
          ),
      ],
    );
  }
}
