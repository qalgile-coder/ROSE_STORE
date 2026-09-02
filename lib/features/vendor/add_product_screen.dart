import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _stockController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _categoryController = TextEditingController();
  
  bool _isLoading = false;
  bool _isAvailable = true;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final url = await ref.read(uploadServiceProvider).pickAndUploadImage(
      context: context,
      folder: 'products',
    );
    
    if (url != null) {
      setState(() {
        _uploadedImageUrl = url;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and upload an image'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userModelProvider).value;
      if (user == null || user.shopId == null) throw Exception('Session error. Please log in again.');

      final product = ProductModel(
        id: '', 
        vendorId: user.uid,
        shopId: user.shopId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        discount: double.parse(_discountController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        unit: _unitController.text.trim(),
        imageUrl: _uploadedImageUrl!,
        category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
        isAvailable: _isAvailable,
        createdAt: DateTime.now(),
      );

      await ref.read(vendorServiceProvider).addProduct(product);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('PRODUCT VISUALS', colorScheme),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.1)),
                    image: _uploadedImageUrl != null ? DecorationImage(image: NetworkImage(_uploadedImageUrl!), fit: BoxFit.cover) : null,
                    boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
                  ),
                  child: _uploadedImageUrl == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.add_a_photo_rounded, size: 32, color: colorScheme.primary),
                            ),
                            const SizedBox(height: 16),
                            Text('Upload product photo', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ) 
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.45),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionHeader('PRODUCT DETAILS', colorScheme),
              const SizedBox(height: 16),
              _buildModernField(_nameController, 'Product Name', Icons.shopping_bag_rounded, colorScheme, isLight),
              const SizedBox(height: 16),
              _buildModernField(_descriptionController, 'Description', Icons.description_rounded, colorScheme, isLight, maxLines: 4),
              const SizedBox(height: 16),
              _buildModernField(_categoryController, 'Category (e.g. Dairy, Fruits)', Icons.category_rounded, colorScheme, isLight, isRequired: false),
              
              const SizedBox(height: 32),
              _buildSectionHeader('PRICING & STOCK', colorScheme),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModernField(_priceController, 'Price (Rs)', Icons.payments_rounded, colorScheme, isLight, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModernField(_discountController, 'Discount %', Icons.percent_rounded, colorScheme, isLight, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModernField(_stockController, 'Initial Stock', Icons.inventory_2_rounded, colorScheme, isLight, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModernField(_unitController, 'Unit (pcs, kg)', Icons.scale_rounded, colorScheme, isLight)),
                ],
              ),
              
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Product is Available', style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    Switch.adaptive(
                      value: _isAvailable,
                      onChanged: (v) => setState(() => _isAvailable = v),
                      activeColor: AppColors.success,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('PUBLISH PRODUCT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.primary.withOpacity(0.7),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, ColorScheme colorScheme, bool isLight, {int maxLines = 1, TextInputType? keyboardType, bool isRequired = true}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)] : null,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05))
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05))
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (v) => (isRequired && (v == null || v.isEmpty)) ? 'Required field' : null,
      ),
    );
  }
}
