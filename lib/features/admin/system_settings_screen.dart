import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../models/system_settings_model.dart';

class SystemSettingsScreen extends ConsumerWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsAsync = ref.watch(systemSettingsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('System Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildSectionHeader(context, 'MARKETPLACE CONFIG'),
            _buildSettingTile(
              context, 
              icon: Icons.category_rounded, 
              title: 'Categories', 
              subtitle: 'Manage store categories',
              onTap: () => context.push('/admin/categories')
            ),
            _buildSettingTile(
              context, 
              icon: Icons.photo_library_rounded, 
              title: 'Shop Banners', 
              subtitle: 'Manage promotional sliders',
              onTap: () => context.push('/admin/shops') // Shop management handles banners
            ),
            _buildSettingTile(
              context, 
              icon: Icons.confirmation_number_rounded, 
              title: 'Global Coupons', 
              subtitle: 'Platform-wide discounts',
              onTap: () => context.push('/admin/coupons')
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'FINANCIAL SETTINGS'),
            _buildSettingTile(
              context, 
              icon: Icons.delivery_dining_rounded, 
              title: 'Base Delivery Charge', 
              subtitle: 'Current: Rs ${settings.deliveryCharge.toInt()}',
              onTap: () => _showEditValueDialog(context, ref, 'Delivery Charge', 'deliveryCharge', settings.deliveryCharge.toString())
            ),
            _buildSettingTile(
              context, 
              icon: Icons.receipt_rounded, 
              title: 'Tax Percentage', 
              subtitle: 'Current: ${settings.taxPercentage}%',
              onTap: () => _showEditValueDialog(context, ref, 'Tax Percentage', 'taxPercentage', settings.taxPercentage.toString())
            ),
            _buildSettingTile(
              context, 
              icon: Icons.percent_rounded, 
              title: 'Platform Commission', 
              subtitle: 'Current: ${settings.platformCommission}%',
              onTap: () => _showEditValueDialog(context, ref, 'Commission (%)', 'platformCommission', settings.platformCommission.toString())
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(context, 'APP CONFIGURATION'),
            _buildSwitchTile(
              context, 
              icon: Icons.settings_suggest_rounded,
              title: 'Maintenance Mode', 
              value: settings.maintenanceMode,
              onChanged: (val) {
                ref.read(adminServiceProvider).updateSystemSettings({'maintenanceMode': val});
              },
            ),
            _buildSettingTile(
              context, 
              icon: Icons.terminal_rounded, 
              title: 'System Info', 
              subtitle: 'Cloud health & stats',
              onTap: () => context.push('/admin/system-info')
            ),
            _buildSettingTile(
              context, 
              icon: Icons.info_outline_rounded, 
              title: 'App Version', 
              subtitle: 'Build: ${settings.appVersion}', 
              onTap: () => _showEditValueDialog(context, ref, 'App Version', 'appVersion', settings.appVersion)
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(context, 'DATA MANAGEMENT'),
            _buildSettingTile(
              context, 
              icon: Icons.backup_rounded, 
              title: 'Export Database (JSON)', 
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database export started...')));
              }
            ),
            _buildSettingTile(
              context, 
              icon: Icons.restore_rounded, 
              title: 'Clear Cache', 
              color: const Color(0xFFF59E0B), 
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local cache cleared.')));
              }
            ),
            
            const SizedBox(height: 40),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }

  void _showEditValueDialog(BuildContext context, WidgetRef ref, String title, String key, String initialValue) {
    final controller = TextEditingController(text: initialValue);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: (key == 'appVersion') ? TextInputType.text : TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter new value',
            filled: true,
            fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final dynamic val = (key == 'appVersion') ? controller.text.trim() : double.tryParse(controller.text) ?? 0.0;
              ref.read(adminServiceProvider).updateSystemSettings({key: val});
              Navigator.pop(context);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
          ),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)) : null,
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
