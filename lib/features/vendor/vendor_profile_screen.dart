import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/developer_section.dart';
import '../../core/providers.dart';
import '../../core/settings_provider.dart';
import '../../core/localization.dart';
import '../../theme/app_colors.dart';
import './widgets/vendor_bottom_nav.dart';
import '../../core/widgets/password_dialogs.dart';
import '../../models/user_model.dart';
import '../../models/shop_model.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';

class VendorProfileScreen extends ConsumerWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final userAsync = ref.watch(userModelProvider);
    final shopAsync = ref.watch(currentShopProvider);
    final productsAsync = ref.watch(shopProductsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('my_profile'.tr(ref), style: const TextStyle(fontWeight: FontWeight.w900)),
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
          if (user == null) return const Center(child: Text('User not found'));
          final shop = shopAsync.asData?.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildShopCard(context, ref, user, shop),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'Total Revenue',
                        value: 'Rs ${NumberFormat.compact().format(user.totalEarnings)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatBox(
                        label: 'Products',
                        value: (productsAsync.value?.length ?? 0).toString(),
                        icon: Icons.inventory_2_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'SHOP CONTROLS', color: colorScheme.primary),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.storefront_rounded,
                      title: 'Edit Shop Details',
                      subtitle: 'Name, category, and banner',
                      onTap: () => context.push('/vendor/edit-shop'),
                    ),
                    _SettingsTile(
                      icon: Icons.account_balance_rounded,
                      title: 'Earnings & Payouts',
                      subtitle: 'Withdrawals and sales history',
                      onTap: () => context.push('/vendor/earnings'),
                    ),
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Bank Details',
                      subtitle: 'Update payout account info',
                      onTap: () => _showBankInfoDialog(context, ref, user),
                    ),
                    _SettingsTile(
                      icon: Icons.insights_rounded,
                      title: 'Sales Analytics',
                      subtitle: 'Detailed performance reports',
                      onTap: () => context.push('/vendor/analytics'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'ENGAGEMENT', color: colorScheme.primary),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Customer Reviews',
                      subtitle: 'View feedback from buyers',
                      onTap: () => context.push('/vendor/reviews'),
                    ),
                    _SettingsTile(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Promo Coupons',
                      subtitle: 'Manage discount codes',
                      onTap: () => context.push('/vendor/coupons'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _SectionHeader(title: 'ACCOUNT & SECURITY', color: colorScheme.primary),
                const SizedBox(height: 12),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your security credentials',
                      onTap: () => PasswordDialogs.showChangePasswordDialog(context, ref),
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'App Language',
                      subtitle: ref.watch(settingsProvider).locale.languageCode == 'en' ? 'English' : 'Urdu',
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
                    backgroundColor: AppColors.error.withOpacity(0.1),
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Zen Mart Pro • v1.0.2',
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 3),
    );
  }

  Widget _buildShopCard(BuildContext context, WidgetRef ref, UserModel user, ShopModel? shop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40)] : null,
        border: isLight ? Border.all(color: colorScheme.outline.withOpacity(0.05)) : null,
      ),
      child: Column(
        children: [
          // Banner Area
          GestureDetector(
            onTap: () => _uploadShopImage(context, ref, shop?.id, true),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                image: shop?.bannerImage != null ? DecorationImage(image: NetworkImage(shop!.bannerImage!), fit: BoxFit.cover) : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (shop?.bannerImage == null)
                    Center(child: Icon(Icons.add_photo_alternate_outlined, color: colorScheme.onSurface.withOpacity(0.1), size: 32)),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.24), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  Positioned(
                    bottom: -45,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _uploadShopImage(context, ref, shop?.id, false),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: colorScheme.primary.withOpacity(0.2),
                                backgroundImage: (shop?.logoUrl != null && shop!.logoUrl!.isNotEmpty) ? NetworkImage(shop.logoUrl!) : null,
                                child: (shop?.logoUrl == null || shop!.logoUrl!.isEmpty)
                                    ? Text(shop?.name.substring(0, 1).toUpperCase() ?? 'V',
                                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: colorScheme.primary))
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 2)),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 54),
          Text(shop?.name ?? 'Loading Shop...', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(user.email, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusBadge(icon: Icons.star_rounded, label: '${user.rating} Rating', color: Colors.orange),
              const SizedBox(width: 12),
              _StatusBadge(icon: Icons.verified_user_rounded, label: 'Verified Store', color: Colors.blue),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AsyncValue<List<ProductModel>> products, AsyncValue<List<OrderModel>> orders, UserModel user) {
    return const SizedBox.shrink(); // Integrated into main build above
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
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Payout Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your settlement account details where you will receive your earnings.', style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
              const SizedBox(height: 24),
              TextField(
                controller: bankNameController, 
                decoration: InputDecoration(
                  labelText: 'Bank / Wallet Name', 
                  hintText: 'e.g. HBL, JazzCash, EasyPaisa',
                  prefixIcon: const Icon(Icons.account_balance_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController, 
                decoration: InputDecoration(
                  labelText: 'Account Title', 
                  hintText: 'e.g. John Doe',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountController, 
                decoration: InputDecoration(
                  labelText: 'Account Number / IBAN', 
                  hintText: 'Enter full account or wallet ID',
                  prefixIcon: const Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (bankNameController.text.isEmpty || accountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
                return;
              }
              await ref.read(vendorServiceProvider).updateBankDetails(user.uid, {
                'bankName': bankNameController.text.trim(),
                'accountNumber': accountController.text.trim(),
                'accountTitle': titleController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank details updated successfully!'), backgroundColor: AppColors.success));
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('SAVE SETTINGS'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your vendor session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('STAY')),
          TextButton(
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              context.go('/welcome');
            },
            child: const Text('SIGN OUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _uploadShopImage(BuildContext context, WidgetRef ref, String? shopId, bool isBanner) async {
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
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusBadge({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))]));
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)] : null,
        border: isLight ? Border.all(color: theme.colorScheme.outline.withOpacity(0.05)) : null,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withOpacity(0.6), letterSpacing: 2))]);
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
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
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14)), 
        child: Icon(icon, color: theme.colorScheme.primary, size: 22)
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSurface.withOpacity(0.15), size: 14),
    );
  }
}
