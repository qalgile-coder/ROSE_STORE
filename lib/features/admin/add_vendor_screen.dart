import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';

class AddVendorScreen extends ConsumerStatefulWidget {
  const AddVendorScreen({super.key});

  @override
  ConsumerState<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends ConsumerState<AddVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Vendor Details
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Shop Details
  final _shopNameController = TextEditingController();
  String? _selectedCategory;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _createVendor() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).createSubUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'vendor',
        shopName: _shopNameController.text.trim(),
        shopCategory: _selectedCategory!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor and Shop created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Register New Vendor',
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a vendor account and assign them a new shop.',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    
                    const _SectionTitle(title: 'Vendor Information'),
                    const SizedBox(height: 16),
                    _buildFormCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            context: context,
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context: context,
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            validator: (v) => v!.isEmpty || !v.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context: context,
                            controller: _passwordController,
                            label: 'Initial Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const _SectionTitle(title: 'Shop Information'),
                    const SizedBox(height: 16),
                    _buildFormCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            context: context,
                            controller: _shopNameController,
                            label: 'Shop Name',
                            icon: Icons.storefront_rounded,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          ref.watch(allCategoriesStreamProvider).when(
                            data: (cats) => DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              dropdownColor: colorScheme.surface,
                              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: 'Category',
                                labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary, size: 20),
                                filled: true,
                                fillColor: colorScheme.onSurface.withValues(alpha: 0.02),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                              items: cats.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _selectedCategory = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) => Text('Error loading categories', style: TextStyle(color: colorScheme.error)),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createVendor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('CREATE VENDOR & SHOP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
        filled: true,
        fillColor: colorScheme.onSurface.withValues(alpha: 0.02),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title.toUpperCase(),
      style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }
}
