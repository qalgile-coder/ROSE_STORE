import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../theme/app_colors.dart';

class EditShopScreen extends ConsumerStatefulWidget {
  const EditShopScreen({super.key});

  @override
  ConsumerState<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends ConsumerState<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _hoursController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final shop = ref.read(currentShopProvider).asData?.value;
    _nameController = TextEditingController(text: shop?.name);
    _descController = TextEditingController(text: shop?.description);
    _phoneController = TextEditingController(text: shop?.phone);
    _addressController = TextEditingController(text: shop?.address);
    _hoursController = TextEditingController(text: shop?.openingHours);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final shop = ref.read(currentShopProvider).asData?.value;
    if (shop == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(vendorServiceProvider).updateShopData(shop.id, {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'openingHours': _hoursController.text.trim(),
      });
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop updated successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
    final shop = ref.watch(currentShopProvider).asData?.value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Store Profile', style: TextStyle(fontWeight: FontWeight.w900)),
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
              _buildImagePickers(shop, colorScheme, isLight),
              const SizedBox(height: 48),
              
              _buildSectionHeader('BASIC INFORMATION', colorScheme),
              const SizedBox(height: 16),
              _buildModernField(_nameController, 'Store Name', Icons.storefront_rounded, colorScheme, isLight),
              const SizedBox(height: 16),
              _buildModernField(_descController, 'Store Description', Icons.description_rounded, colorScheme, isLight, maxLines: 4),
              
              const SizedBox(height: 32),
              _buildSectionHeader('CONTACT & LOGISTICS', colorScheme),
              const SizedBox(height: 16),
              _buildModernField(_phoneController, 'Public Contact Number', Icons.phone_rounded, colorScheme, isLight, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildModernField(_addressController, 'Store Physical Address', Icons.location_on_rounded, colorScheme, isLight),
              const SizedBox(height: 16),
              _buildModernField(_hoursController, 'Opening Hours (e.g. 9 AM - 10 PM)', Icons.access_time_filled_rounded, colorScheme, isLight),
              
              const SizedBox(height: 48),
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('SAVE STORE PROFILE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickers(dynamic shop, ColorScheme colorScheme, bool isLight) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => _uploadImage(isBanner: true, shopId: shop?.id),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                  image: shop?.bannerImage != null ? DecorationImage(image: NetworkImage(shop.bannerImage!), fit: BoxFit.cover) : null,
                  boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
                ),
                child: shop?.bannerImage == null ? Center(child: Icon(Icons.add_photo_alternate_rounded, color: colorScheme.primary.withOpacity(0.3), size: 40)) : null,
              ),
            ),
            Positioned(
              bottom: -40,
              left: 20,
              child: GestureDetector(
                onTap: () => _uploadImage(isBanner: false, shopId: shop?.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: colorScheme.background, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    backgroundImage: (shop?.logoUrl != null && shop!.logoUrl!.isNotEmpty) ? NetworkImage(shop.logoUrl!) : null,
                    child: (shop?.logoUrl == null || shop!.logoUrl!.isEmpty) ? Icon(Icons.storefront_rounded, color: colorScheme.primary, size: 40) : null,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => _uploadImage(isBanner: true, shopId: shop?.id),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _uploadImage({required bool isBanner, String? shopId}) async {
    if (shopId == null) return;
    final url = await ref.read(uploadServiceProvider).pickAndUploadImage(
      context: context, 
      folder: isBanner ? 'shop_banners' : 'shop_logos',
      source: ImageSource.gallery,
    );
    if (url != null) {
      if (isBanner) {
        await ref.read(vendorServiceProvider).updateShopBanner(shopId, url);
      } else {
        await ref.read(vendorServiceProvider).updateShopLogo(shopId, url);
      }
    }
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

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, ColorScheme colorScheme, bool isLight, {int maxLines = 1, TextInputType? keyboardType}) {
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
        validator: (v) => v!.isEmpty ? 'Required field' : null,
      ),
    );
  }
}
