import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/developer_section.dart';
import '../../core/providers.dart';
import '../../core/settings_provider.dart';
import '../../theme/app_colors.dart';
import './widgets/rider_bottom_nav.dart';
import '../../core/widgets/password_dialogs.dart';
import '../../models/user_model.dart';

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userAsync = ref.watch(userModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rider Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push('/support'),
            icon: Icon(Icons.help_outline_rounded, color: colorScheme.onSurface),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildRiderCard(context, user, colorScheme),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'TOTAL EARNINGS',
                        value: 'Rs ${NumberFormat.compact().format(user.totalEarnings)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.success,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatBox(
                        label: 'DELIVERIES',
                        value: user.totalDeliveries.toString(),
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.rider,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'WORK & PERFORMANCE', color: colorScheme.primary),
                const SizedBox(height: 12),
                _SettingsGroup(
                  colorScheme: colorScheme,
                  children: [
                    _SettingsTile(
                      icon: Icons.analytics_rounded,
                      title: 'Performance Stats',
                      subtitle: 'Ratings and feedback metrics',
                      onTap: () => context.push('/rider/performance'),
                      colorScheme: colorScheme,
                    ),
                    _SettingsTile(
                      icon: Icons.history_rounded,
                      title: 'Delivery History',
                      subtitle: 'Review your past tasks',
                      onTap: () => context.push('/rider/history'),
                      colorScheme: colorScheme,
                    ),
                    _SettingsTile(
                      icon: Icons.payments_rounded,
                      title: 'Payout Summary',
                      subtitle: 'Manage your earnings',
                      onTap: () => context.push('/rider/earnings'),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'COMPLIANCE', color: colorScheme.primary),
                const SizedBox(height: 12),
                _SettingsGroup(
                  colorScheme: colorScheme,
                  children: [
                    _SettingsTile(
                      icon: Icons.directions_bike_rounded,
                      title: 'Vehicle Details',
                      subtitle: 'Verification and insurance',
                      onTap: () => context.push('/rider/vehicle'),
                      colorScheme: colorScheme,
                    ),
                    _SettingsTile(
                      icon: Icons.description_rounded,
                      title: 'Legal Documents',
                      subtitle: 'License and verification',
                      onTap: () => context.push('/rider/documents'),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'ACCOUNT & SECURITY', color: colorScheme.primary),
                const SizedBox(height: 12),
                _SettingsGroup(
                  colorScheme: colorScheme,
                  children: [
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Payout Settings',
                      subtitle: 'Update your bank details',
                      onTap: () => _showBankInfoDialog(context, ref, user),
                      colorScheme: colorScheme,
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update security credentials',
                      onTap: () => PasswordDialogs.showChangePasswordDialog(context, ref),
                      colorScheme: colorScheme,
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'App Language',
                      subtitle: ref.watch(settingsProvider).locale.languageCode == 'en' ? 'English' : 'Urdu',
                      onTap: () => _showLanguageDialog(context, ref),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const DeveloperSection(),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                    label: const Text('GO OFFLINE & LOGOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Zen Mart Pro • Rider v1.0.2',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: const RiderBottomNav(currentIndex: 3),
    );
  }

  Widget _buildRiderCard(BuildContext context, UserModel user, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.rider.withValues(alpha: 0.3), width: 2)),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.rider.withValues(alpha: 0.1),
                  backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty) ? NetworkImage(user.profilePicture!) : null,
                  child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                      ? Text(user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.rider))
                      : null,
                ),
              ),
              if (user.verificationStatus == VerificationStatus.verified)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 3)),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('RIDER ID: ${user.uid.substring(0, 8).toUpperCase()}', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(icon: Icons.star_rounded, label: '${user.rating} Rating', color: Colors.orange),
              const SizedBox(width: 12),
              _Badge(
                icon: user.isOnline ? Icons.online_prediction_rounded : Icons.offline_bolt_rounded,
                label: user.isOnline ? 'ONLINE' : 'OFFLINE',
                color: user.isOnline ? AppColors.success : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Select Language', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              trailing: ref.watch(settingsProvider).locale.languageCode == 'en' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () { ref.read(settingsProvider.notifier).setLocale('en'); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('Urdu (اردو)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              trailing: ref.watch(settingsProvider).locale.languageCode == 'ur' ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () { ref.read(settingsProvider.notifier).setLocale('ur'); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showBankInfoDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final accountController = TextEditingController(text: user.bankDetails?['accountNumber'] ?? '');
    final bankNameController = TextEditingController(text: user.bankDetails?['bankName'] ?? '');
    final titleController = TextEditingController(text: user.bankDetails?['accountTitle'] ?? '');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Payout Settings', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your settlement account details where you will receive your earnings.', style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
              const SizedBox(height: 24),
              TextField(
                controller: bankNameController, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bank / Wallet Name', 
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'e.g. HBL, JazzCash, EasyPaisa',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.rider),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Account Title', 
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'e.g. John Doe',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.rider),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountController, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Account Number / ID', 
                  labelStyle: const TextStyle(color: Colors.white60),
                  hintText: 'Enter full account or wallet ID',
                  hintStyle: const TextStyle(color: Colors.white24),
                  prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.rider),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (bankNameController.text.isEmpty || accountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
                return;
              }
              await ref.read(riderServiceProvider).updateProfile(user.uid, {
                'bankDetails': {
                  'bankName': bankNameController.text.trim(),
                  'accountNumber': accountController.text.trim(),
                  'accountTitle': titleController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank details updated successfully!'), backgroundColor: AppColors.success));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rider,
              minimumSize: const Size(120, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('SAVE SETTINGS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Go Offline?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Logging out will set your status to Offline. You will not receive any new requests.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: TextStyle(color: Colors.white.withValues(alpha: 0.4)))),
          TextButton(
            onPressed: () async {
              final auth = ref.read(authServiceProvider);
              final riderService = ref.read(riderServiceProvider);
              final uid = ref.read(userModelProvider).value?.uid;
              
              if (uid != null) {
                await riderService.toggleOnlineStatus(uid, false);
              }
              await auth.signOut();
              if (context.mounted) context.go('/welcome');
            },
            child: const Text('LOGOUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))]));
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color, required this.colorScheme});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(32), border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05))), child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 16), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5))]));
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 2))]);
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final ColorScheme colorScheme;
  const _SettingsGroup({required this.children, required this.colorScheme});
  @override
  Widget build(BuildContext context) => Material(
        color: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05)),
        ),
        child: Column(children: children),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, required this.colorScheme});
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.rider.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.rider, size: 22)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w500)), trailing: Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withValues(alpha: 0.15), size: 14));
}
