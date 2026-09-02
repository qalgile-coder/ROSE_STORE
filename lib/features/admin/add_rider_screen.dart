import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';

class AddRiderScreen extends ConsumerStatefulWidget {
  const AddRiderScreen({super.key});

  @override
  ConsumerState<AddRiderScreen> createState() => _AddRiderScreenState();
}

class _AddRiderScreenState extends ConsumerState<AddRiderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Rider Details
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Vehicle Details
  final _vehicleInfoController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _vehicleInfoController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _createRider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).createSubUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'rider',
        vehicleInfo: _vehicleInfoController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider account created successfully!')),
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
                      'Register New Rider',
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a rider account and provide vehicle credentials.',
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    
                    const _SectionTitle(title: 'Rider Information'),
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
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context: context,
                            controller: _passwordController,
                            label: 'Temporary Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const _SectionTitle(title: 'Vehicle Details'),
                    const SizedBox(height: 16),
                    _buildFormCard(
                      child: Column(
                        children: [
                          _buildTextField(
                            context: context,
                            controller: _vehicleInfoController,
                            label: 'Vehicle (e.g. Honda CD 70 - ABC 123)',
                            icon: Icons.directions_bike_rounded,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context: context,
                            controller: _licenseNumberController,
                            label: 'License Number',
                            icon: Icons.badge_outlined,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createRider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6B08A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('CREATE RIDER ACCOUNT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
        prefixIcon: Icon(icon, color: const Color(0xFFD6B08A), size: 20),
        filled: true,
        fillColor: colorScheme.onSurface.withValues(alpha: 0.02),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD6B08A), width: 1.5)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: Color(0xFFD6B08A), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }
}
