import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../models/coupon_model.dart';
import '../../theme/app_colors.dart';

class CouponManagementScreen extends ConsumerWidget {
  const CouponManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final couponsAsync = ref.watch(shopCouponsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Store Coupons', style: TextStyle(fontWeight: FontWeight.w900)),
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
      body: couponsAsync.when(
        data: (coupons) {
          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.confirmation_number_rounded, size: 64, color: AppColors.warning),
                  ),
                  const SizedBox(height: 24),
                  Text('No active coupons', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Create discount codes to boost sales!', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _CouponCard(coupon: coupons[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCouponDialog(context, ref),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('NEW COUPON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  void _showCouponDialog(BuildContext context, WidgetRef ref, {CouponModel? coupon}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    
    final codeController = TextEditingController(text: coupon?.code);
    final percentageController = TextEditingController(text: coupon?.discountPercentage.toString());
    final fixedController = TextEditingController(text: coupon?.fixedDiscount.toString());
    final minOrderController = TextEditingController(text: coupon?.minOrderAmount.toString());
    DateTime expiryDate = coupon?.expiryDate ?? DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(coupon == null ? 'Create Coupon' : 'Edit Coupon', style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(codeController, 'COUPON CODE (E.G. SAVE30)', Icons.qr_code_rounded, colorScheme, capitalize: true),
                const SizedBox(height: 16),
                _buildField(percentageController, 'DISCOUNT %', Icons.percent_rounded, colorScheme, keyboard: TextInputType.number),
                const SizedBox(height: 16),
                _buildField(fixedController, 'FIXED RS OFF', Icons.payments_rounded, colorScheme, keyboard: TextInputType.number),
                const SizedBox(height: 16),
                _buildField(minOrderController, 'MIN. ORDER AMOUNT', Icons.shopping_basket_rounded, colorScheme, keyboard: TextInputType.number),
                const SizedBox(height: 24),
                
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiryDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => expiryDate = picked);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EXPIRY DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.onSurface.withOpacity(0.4))),
                            const SizedBox(height: 2),
                            Text(DateFormat('MMM dd, yyyy').format(expiryDate), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                final user = ref.read(userModelProvider).asData?.value;
                if (user?.shopId == null) return;

                final newCoupon = CouponModel(
                  id: coupon?.id ?? '',
                  shopId: user!.shopId!,
                  code: codeController.text.trim().toUpperCase(),
                  discountPercentage: double.tryParse(percentageController.text) ?? 0,
                  fixedDiscount: double.tryParse(fixedController.text) ?? 0,
                  expiryDate: expiryDate,
                  minOrderAmount: double.tryParse(minOrderController.text) ?? 0,
                  isActive: coupon?.isActive ?? true,
                );

                if (coupon == null) {
                  ref.read(vendorServiceProvider).addCoupon(newCoupon);
                } else {
                  ref.read(vendorServiceProvider).updateCoupon(coupon.id, newCoupon.toMap());
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(120, 50)),
              child: Text(coupon == null ? 'CREATE' : 'SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, ColorScheme colorScheme, {bool capitalize = false, TextInputType? keyboard}) {
    return TextFormField(
      controller: controller,
      textCapitalization: capitalize ? TextCapitalization.characters : TextCapitalization.none,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}

class _CouponCard extends ConsumerWidget {
  final CouponModel coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final bool isExpired = coupon.expiryDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.05)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 54, width: 54,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.confirmation_number_rounded, color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.code,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.discountPercentage > 0 
                          ? '${coupon.discountPercentage.round()}% OFF YOUR ORDER' 
                          : 'Rs ${coupon.fixedDiscount.round()} DISCOUNT',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch.adaptive(
                  value: coupon.isActive && !isExpired,
                  activeColor: AppColors.success,
                  onChanged: isExpired ? null : (v) {
                    ref.read(vendorServiceProvider).updateCoupon(coupon.id, {'isActive': v});
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MIN. SPEND: RS ${coupon.minOrderAmount.round()}', 
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: isExpired ? AppColors.error : colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 6),
                      Text(
                        isExpired ? 'EXPIRED' : 'VALID UNTIL ${DateFormat('MMM dd, yyyy').format(coupon.expiryDate).toUpperCase()}',
                        style: TextStyle(
                          color: isExpired ? AppColors.error : colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _IconAction(
                    icon: Icons.edit_rounded, 
                    onTap: () => const CouponManagementScreen()._showCouponDialog(context, ref, coupon: coupon),
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  _IconAction(
                    icon: Icons.delete_sweep_rounded, 
                    onTap: () => _showDeleteDialog(context, ref, colorScheme),
                    color: AppColors.error.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete Coupon?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('This will permanently remove "${coupon.code}". Customers will no longer be able to use it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              ref.read(vendorServiceProvider).deleteCoupon(coupon.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _IconAction({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
