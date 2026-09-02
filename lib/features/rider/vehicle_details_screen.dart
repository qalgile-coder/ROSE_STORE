import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/user_model.dart';
import '../../theme/app_colors.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  ConsumerState<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  bool _isEditing = false;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _colorController;
  late TextEditingController _plateController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userModelProvider).asData?.value;
    _brandController = TextEditingController(text: user?.vehicleBrand ?? 'Honda');
    _modelController = TextEditingController(text: user?.vehicleModel ?? 'CD 70');
    _colorController = TextEditingController(text: user?.vehicleColor ?? 'Red');
    _plateController = TextEditingController(text: user?.vehicleInfo ?? 'ABC-1234');
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _saveVehicleInfo() async {
    final user = ref.read(userModelProvider).asData?.value;
    if (user == null) return;

    await ref.read(riderServiceProvider).updateProfile(user.uid, {
      'vehicleBrand': _brandController.text.trim(),
      'vehicleModel': _modelController.text.trim(),
      'vehicleColor': _colorController.text.trim(),
      'vehicleInfo': _plateController.text.trim(),
    });

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle Information Updated'), backgroundColor: AppColors.success),
      );
    }
  }

  void _updateVehiclePhoto() async {
    final user = ref.read(userModelProvider).asData?.value;
    if (user == null) return;

    final url = await ref.read(uploadServiceProvider).pickAndUploadImage(
      context: context,
      folder: 'rider_vehicles',
    );

    if (url != null) {
      await ref.read(riderServiceProvider).updateProfile(user.uid, {'vehicleImage': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle photo updated'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(userModelProvider).asData?.value;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vehicle Asset', style: TextStyle(fontWeight: FontWeight.w900)),
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
        actions: [
          IconButton(
            onPressed: () {
              if (_isEditing) {
                _saveVehicleInfo();
              } else {
                setState(() => _isEditing = true);
              }
            },
            icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded, color: AppColors.rider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehiclePhoto(user, colorScheme),
            const SizedBox(height: 40),
            _SectionTitle(title: 'TECHNICAL SPECIFICATIONS', color: colorScheme.primary),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface, 
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _VehicleInfoRow(label: 'VEHICLE TYPE', value: 'Motorcycle', icon: Icons.directions_bike_rounded, colorScheme: colorScheme),
                  _VehicleInfoRow(
                    label: 'MANUFACTURER', 
                    value: _brandController.text, 
                    isEditable: _isEditing, 
                    controller: _brandController,
                    icon: Icons.branding_watermark_rounded,
                    colorScheme: colorScheme,
                  ),
                  _VehicleInfoRow(
                    label: 'MODEL / VERSION', 
                    value: _modelController.text, 
                    isEditable: _isEditing, 
                    controller: _modelController,
                    icon: Icons.layers_rounded,
                    colorScheme: colorScheme,
                  ),
                  _VehicleInfoRow(
                    label: 'EXTERIOR COLOR', 
                    value: _colorController.text, 
                    isEditable: _isEditing, 
                    controller: _colorController,
                    icon: Icons.color_lens_rounded,
                    colorScheme: colorScheme,
                  ),
                  _VehicleInfoRow(
                    label: 'PLATE NUMBER', 
                    value: _plateController.text, 
                    isEditable: _isEditing, 
                    controller: _plateController,
                    icon: Icons.tag_rounded,
                    colorScheme: colorScheme,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _SectionTitle(title: 'REGISTRATION & LEGAL', color: colorScheme.primary),
            const SizedBox(height: 16),
            _DocumentTile(title: 'Vehicle Registration (Smart Card)', status: 'Verified', icon: Icons.verified_user_rounded, colorScheme: colorScheme),
            _DocumentTile(title: 'Asset Insurance Policy', status: 'Active', icon: Icons.security_rounded, colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclePhoto(UserModel? user, ColorScheme colorScheme) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
              image: DecorationImage(
                image: NetworkImage(user?.vehicleImage ?? 'https://images.unsplash.com/photo-1444491741275-3747c53c99b4?auto=format&fit=crop&q=80&w=400'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: -16,
              right: 24,
              child: GestureDetector(
                onTap: _updateVehiclePhoto,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.rider, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 4)),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 2))]);
}

class _VehicleInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isEditable;
  final TextEditingController? controller;
  final bool isLast;
  final ColorScheme colorScheme;

  const _VehicleInfoRow({required this.label, required this.value, required this.icon, this.isEditable = false, this.controller, this.isLast = false, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.rider.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.rider, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                if (isEditable && controller != null)
                  TextField(
                    controller: controller,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  )
                else
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final ColorScheme colorScheme;

  const _DocumentTile({required this.title, required this.status, required this.icon, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status.toUpperCase(), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}
