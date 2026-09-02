import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/developer_section.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../core/widgets/password_dialogs.dart';
import '../../models/user_model.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shopsCount = ref.watch(totalShopsCountProvider).asData?.value ?? 0;
    final ridersCount = ref.watch(totalRidersCountProvider).asData?.value ?? 0;
    final customersCount = ref.watch(totalCustomersCountProvider).asData?.value ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Admin not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Admin Identity Card
                _buildAdminCard(context, user),
                const SizedBox(height: 32),

                const _SectionHeader(title: 'System Information'),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => context.push('/admin/system-info'),
                  borderRadius: BorderRadius.circular(20),
                  child: _SystemInfoGrid(
                    shops: shopsCount,
                    riders: ridersCount,
                    customers: customersCount,
                  ),
                ),
                const SizedBox(height: 32),

                const _SectionHeader(title: 'Administrative Controls'),
                const SizedBox(height: 16),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Security Settings',
                      subtitle: '2FA, Active Sessions, Login History',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Support Management',
                      subtitle: 'Manage support tickets and replies',
                      onTap: () => context.push('/admin/support'),
                    ),
                    _SettingsTile(
                      icon: Icons.settings_applications_outlined,
                      title: 'System Settings',
                      subtitle: 'App version, server status, maintenance',
                      onTap: () => context.push('/admin/system'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const _SectionHeader(title: 'Personal & Security'),
                const SizedBox(height: 16),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your administrative password',
                      onTap: () => PasswordDialogs.showChangePasswordDialog(context, ref),
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'App Language',
                      subtitle: 'English (US)',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                const DeveloperSection(),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('LOGOUT ADMIN SESSION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      minimumSize: const Size(0, 64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2)),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty) ? NetworkImage(user.profilePicture!) : null,
              child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                  ? Text(user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: colorScheme.primary))
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(user.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.onSurface, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('SUPER ADMIN', style: TextStyle(color: colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 24),
          Text(user.email, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('ID: ${user.uid.substring(0, 12).toUpperCase()}', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Are you sure you want to log out from the Super Admin panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              context.go('/welcome');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SystemInfoGrid extends StatelessWidget {
  final int shops;
  final int riders;
  final int customers;
  const _SystemInfoGrid({required this.shops, required this.riders, required this.customers});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _InfoBox(label: 'Shops', value: shops.toString(), color: Colors.indigo)),
        const SizedBox(width: 12),
        Expanded(child: _InfoBox(label: 'Riders', value: riders.toString(), color: Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _InfoBox(label: 'Users', value: customers.toString(), color: Colors.green)),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoBox({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1))
      ), 
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)), 
          const SizedBox(height: 4), 
          Text(label.toUpperCase(), style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5))
        ]
      )
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        const SizedBox(width: 8), 
        Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withValues(alpha: 0.3), letterSpacing: 1.5))
      ]
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), 
      leading: Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), 
        child: Icon(icon, color: colorScheme.primary, size: 20)
      ), 
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface)), 
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.4))), 
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 20)
    );
  }
}
