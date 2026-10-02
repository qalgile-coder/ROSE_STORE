import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/product_model.dart';
import '../../theme/app_colors.dart';
import '../../color_helper.dart';

final realTimeProductsStreamProvider = StreamProvider.autoDispose<List<ProductModel>>((ref) {
  return ref.watch(customerServiceProvider).getProductsStream();
});

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
  
  String? _selectedCategoryKey;

  final List<Map<String, String>> _categories = [
    {'name': 'Men Clothing', 'key': 'mens_clothing'},
    {'name': 'Women Clothing', 'key': 'womens_clothing'},
    {'name': 'Accessories', 'key': 'accessories'},
    {'name': 'Cosmetics', 'key': 'cosmetics'},
    {'name': 'Men Shoes', 'key': 'mens_shoes'},
    {'name': 'Women Shoes', 'key': 'womens_shoes'},
    {'name': 'Kids Clothing', 'key': 'kids_clothing'},
    {'name': 'Bags & Wallets', 'key': 'bags_wallets'},
    {'name': 'Perfumes', 'key': 'perfumes'},
  ];
  
  String _selectedCurrency = 'SDG';

  final List<Map<String, String>> _currencies = [
    {'label': 'Sudan (SDG)', 'symbol': 'SDG'},
    {'label': 'Egypt (EGP)', 'symbol': 'EGP'},
    {'label': 'Saudi Arabia (SAR)', 'symbol': 'SAR'},
  ];

  final List<String> _availableSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', 'Free Size'];
  final List<String> _selectedSizes = [];

  final List<String> _selectedColors = [];

  bool _isLoading = false;
  bool _isAvailable = true;
  
  final List<File> _pickedImages = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          _pickedImages.add(File(file.path));
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select at least one image'),
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

      List<String> uploadedImageUrls = [];
      for (var imageFile in _pickedImages) {
        final uploadedUrl = await ref.read(uploadServiceProvider).uploadFile(
              file: imageFile,
              folder: 'products',
            );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          uploadedImageUrls.add(uploadedUrl);
        }
      }

      if (uploadedImageUrls.isEmpty) {
        throw Exception('Failed to upload images. Please try again.');
      }

      final product = ProductModel(
        id: '', 
        vendorId: user.uid,
        shopId: user.shopId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        currency: _selectedCurrency,
        discount: double.parse(_discountController.text.trim()),
        stock: int.parse(_stockController.text.trim()),
        unit: _unitController.text.trim(),
        imageUrls: uploadedImageUrls,
        imageUrl: uploadedImageUrls.first,
        category: _selectedCategoryKey ?? 'General',
        isAvailable: _isAvailable,
        createdAt: DateTime.now(),
        sizes: _selectedSizes,
        colors: _selectedColors,
      );

      await ref.read(vendorServiceProvider).addProduct(product);
      ref.invalidate(realTimeProductsStreamProvider);
      
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
              _buildSectionHeader('PRODUCT VISUALS (MULTIPLE)', colorScheme),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _pickedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 120,
                            height: 140,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)] : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add_photo_alternate_rounded, size: 28, color: colorScheme.primary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Photos',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final imageIndex = index - 1;
                    final file = _pickedImages[imageIndex];

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              image: DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)] : null,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(imageIndex),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (imageIndex == 0)
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Cover',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionHeader('PRODUCT DETAILS', colorScheme),
              const SizedBox(height: 16),
              _buildModernField(_nameController, 'Product Name', Icons.shopping_bag_rounded, colorScheme, isLight),
              const SizedBox(height: 16),
              _buildModernField(_descriptionController, 'Description', Icons.description_rounded, colorScheme, isLight, maxLines: 4),
              const SizedBox(height: 16),
              
              _buildCategoryDropdown(colorScheme, isLight),

              const SizedBox(height: 32),
              _buildSectionHeader('PRODUCT VARIATIONS (SIZES & COLORS)', colorScheme),
              const SizedBox(height: 16),
              
              Text('Available Sizes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSizes.map((size) {
                  final isSelected = _selectedSizes.contains(size);
                  return ChoiceChip(
                    label: Text(size),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSizes.add(size);
                        } else {
                          _selectedSizes.remove(size);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              Text('Available Colors', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppColorsData.colorMap.entries.map((entry) {
                  final colorHex = entry.key;
                  final colorName = entry.value;
                  final isSelected = _selectedColors.contains(colorHex);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedColors.remove(colorHex);
                        } else {
                          _selectedColors.add(colorHex);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400, width: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            colorName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader('PRICING & STOCK', colorScheme),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildModernField(_priceController, 'Price', Icons.payments_rounded, colorScheme, isLight, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildCurrencyDropdown(colorScheme, isLight),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildModernField(_discountController, 'Discount %', Icons.percent_rounded, colorScheme, isLight, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModernField(_stockController, 'Initial Stock', Icons.inventory_2_rounded, colorScheme, isLight, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModernField(_unitController, 'Unit (pcs, kg)', Icons.scale_rounded, colorScheme, isLight)),
                  const Spacer(),
                ],
              ),
              
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05)),
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

  Widget _buildCategoryDropdown(ColorScheme colorScheme, bool isLight) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)] : null,
      ),
      child: DropdownButtonFormField<String>(
        value: _categories.any((cat) => cat['key'] == _selectedCategoryKey) ? _selectedCategoryKey : null,
        dropdownColor: colorScheme.surface,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary, size: 20),
        decoration: InputDecoration(
          labelText: 'Select Category',
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.category_rounded, color: colorScheme.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05))
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05))
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        items: _categories.map((cat) {
          return DropdownMenuItem<String>(
            value: cat['key'],
            child: Text(
              cat['name']!,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _selectedCategoryKey = val;
          });
        },
        validator: (v) => v == null ? 'Please select a category' : null,
      ),
    );
  }

  Widget _buildCurrencyDropdown(ColorScheme colorScheme, bool isLight) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)] : null,
        border: Border.all(color: colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currencies.any((curr) => curr['symbol'] == _selectedCurrency) ? _selectedCurrency : null,
          dropdownColor: colorScheme.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary, size: 20),
          items: _currencies.map((curr) {
            return DropdownMenuItem<String>(
              value: curr['symbol'],
              child: Text(
                curr['symbol']!,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCurrency = val!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.primary.withValues(alpha: 0.7),
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
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)] : null,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05))
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20), 
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: isLight ? 0.5 : 0.05))
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