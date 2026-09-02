import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/developer_section.dart';
import '../../core/providers.dart';
import '../../core/settings_provider.dart';
import '../../core/localization.dart';
import '../../theme/app_colors.dart';
import './widgets/customer_bottom_nav.dart';
import '../../core/widgets/password_dialogs.dart';
import '../../models/user_model.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);
    final ordersAsync = ref.watch(customerOrdersProvider);
    final wishlistAsync = ref.watch(customerWishlistProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('my_profile'.tr(ref), style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/support'),
            icon: Icon(Icons.help_outline_rounded, color: colorScheme.onSurface),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found', style: TextStyle(color: AppColors.textHint)));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildProfileCard(context, ref, user),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'total_orders'.tr(ref),
                        value: (ordersAsync.value?.length ?? 0).toString(),
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        onTap: () => context.push('/customer/orders'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatBox(
                        label: 'wishlist'.tr(ref),
                        value: (wishlistAsync.value?.length ?? 0).toString(),
                        icon: Icons.favorite_rounded,
                        color: AppColors.error,
                        onTap: () => context.push('/customer/wishlist'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'Rewards & Referrals'),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Invite Friends',
                      subtitle: user.referralCode != null 
                          ? 'Your Code: ${user.referralCode}' 
                          : 'Get your unique invite code',
                      onTap: () {
                        if (user.referralCode == null) {
                          ref.read(authServiceProvider).generateReferralCode(user.uid);
                        } else {
                          // Share logic could be added here
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'account_settings'.tr(ref)),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_rounded,
                      title: 'edit_profile'.tr(ref),
                      subtitle: 'Name, email, and phone',
                      onTap: () => _showEditProfileDialog(context, ref, user),
                    ),
                    _SettingsTile(
                      icon: Icons.location_on_rounded,
                      title: 'saved_addresses'.tr(ref),
                      subtitle: 'Delivery locations',
                      onTap: () => context.push('/customer/addresses'),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_rounded,
                      title: 'Security',
                      subtitle: 'Update your password',
                      onTap: () => PasswordDialogs.showChangePasswordDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'preferences'.tr(ref)),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: isLight ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      title: isLight ? 'Light Theme' : 'Dark Theme',
                      subtitle: isLight ? 'Currently using premium light' : 'Experience in dark mode',
                      trailing: Switch(
                        value: settings.themeMode == ThemeMode.dark, 
                        onChanged: (v) => ref.read(settingsProvider.notifier).toggleTheme(v)
                      ),
                      onTap: () => ref.read(settingsProvider.notifier).toggleTheme(settings.themeMode != ThemeMode.dark),
                    ),
                    _SettingsTile(
                      icon: Icons.translate_rounded,
                      title: 'language'.tr(ref),
                      subtitle: settings.locale.languageCode == 'en' ? 'English' : 'Urdu',
                      onTap: () => _showLanguageDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const DeveloperSection(),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text('sign_out'.tr(ref).toUpperCase()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Zen Mart Pro • v1.0.2',
                  style: TextStyle(color: AppColors.textDisabled, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40)] : null,
        border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.05)) : null,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: isLight ? AppColors.lightSecondaryBackground : AppColors.background,
                  backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty) 
                      ? NetworkImage(user.profilePicture!) 
                      : null,
                  child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                      ? Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: colorScheme.primary)
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _uploadProfilePicture(context, ref, user.uid),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_rounded, color: isLight ? Colors.white : AppColors.background, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            user.name, 
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.5)
          ),
          const SizedBox(height: 4),
          Text(
            user.email, 
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isLight ? colorScheme.primary.withOpacity(0.1) : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Member since ${DateFormat('MMMM yyyy').format(user.createdAt)}',
              style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _uploadProfilePicture(BuildContext context, WidgetRef ref, String uid) async {
    final url = await ref.read(uploadServiceProvider).pickAndUploadImage(
      context: context, 
      folder: 'profile_pictures',
      source: ImageSource.gallery,
    );
    
    if (url != null) {
      await ref.read(authServiceProvider).updateProfilePicture(uid, url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('select_language'.tr(ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageTile(
              label: 'english'.tr(ref), 
              isSelected: ref.watch(settingsProvider).locale.languageCode == 'en', 
              onTap: () { ref.read(settingsProvider.notifier).setLocale('en'); Navigator.pop(context); }
            ),
            _LanguageTile(
              label: 'urdu'.tr(ref), 
              isSelected: ref.watch(settingsProvider).locale.languageCode == 'ur', 
              onTap: () { ref.read(settingsProvider.notifier).setLocale('ur'); Navigator.pop(context); }
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('edit_profile_title'.tr(ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'full_name'.tr(ref))),
            const SizedBox(height: 16),
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'phone_number'.tr(ref))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr(ref), style: const TextStyle(color: AppColors.textHint))),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).updateUserProfile(
                uid: user.uid,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 48)),
            child: Text('save_changes'.tr(ref).toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('sign_out'.tr(ref), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to end your session?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr(ref), style: const TextStyle(color: AppColors.textHint))),
          TextButton(
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              context.go('/welcome');
            },
            child: Text('sign_out'.tr(ref).toUpperCase(), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _LanguageTile({required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatBox({required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)] : null,
          border: isLight ? Border.all(color: colorScheme.outline.withValues(alpha: 0.05)) : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: isLight ? BorderSide(color: colorScheme.outline.withOpacity(0.05)) : BorderSide.none,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light ? colorScheme.primary.withOpacity(0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w500)),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onSurface.withOpacity(0.2), size: 14),
    );
  }
}
