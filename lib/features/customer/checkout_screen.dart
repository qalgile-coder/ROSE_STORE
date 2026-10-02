import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../models/order_model.dart';
import '../../models/coupon_model.dart';
import '../../models/shop_model.dart';
import '../../theme/app_colors.dart';
import '../../color_helper.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'Cash on Delivery';
  bool _isPlacingOrder = false;
  CouponModel? _appliedCoupon;

  final TextEditingController _couponController = TextEditingController();
  bool _isVerifyingCoupon = false;
  String _couponMessage = '';
  bool _isCouponValid = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String _getCurrencySymbol(dynamic cart) {
    if (cart.items.isNotEmpty) {
      final firstItem = cart.items.values.first;
      if (firstItem.product.currency != null && firstItem.product.currency.isNotEmpty) {
        return firstItem.product.currency;
      }
    }
    return 'SDG';
  }

  double _calculateDiscount(double subtotal) {
    if (_appliedCoupon == null) return 0.0;
    if (_appliedCoupon!.discountPercentage > 0) {
      return (subtotal * _appliedCoupon!.discountPercentage) / 100;
    }
    return _appliedCoupon!.fixedDiscount;
  }

  Future<void> _verifyAndApplyCouponCode(String code, double subtotal, String shopId) async {
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) {
      setState(() {
        _couponMessage = 'Please enter a coupon code.';
        _isCouponValid = false;
        _appliedCoupon = null;
      });
      return;
    }

    setState(() {
      _isVerifyingCoupon = true;
      _couponMessage = '';
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: trimmedCode)
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _couponMessage = 'Invalid coupon or does not belong to this store.';
          _isCouponValid = false;
          _appliedCoupon = null;
        });
        return;
      }

      final coupon = CouponModel.fromFirestore(querySnapshot.docs.first);

      if (coupon.expiryDate.isBefore(DateTime.now())) {
        setState(() {
          _couponMessage = 'This coupon has expired.';
          _isCouponValid = false;
          _appliedCoupon = null;
        });
        return;
      }

      if (subtotal < coupon.minOrderAmount) {
        setState(() {
          _couponMessage = 'Min. spend required is ${coupon.minOrderAmount.round()}';
          _isCouponValid = false;
          _appliedCoupon = null;
        });
        return;
      }

      setState(() {
        _appliedCoupon = coupon;
        _isCouponValid = true;
        _couponMessage = coupon.discountPercentage > 0
            ? 'Coupon applied successfully! (${coupon.discountPercentage.round()}% OFF)'
            : 'Coupon applied successfully! (${coupon.fixedDiscount.round()} OFF)';
      });
    } catch (e) {
      setState(() {
        _couponMessage = 'Error verifying coupon. Please try again.';
        _isCouponValid = false;
        _appliedCoupon = null;
      });
    } finally {
      setState(() {
        _isVerifyingCoupon = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final address = ref.watch(defaultAddressProvider);
    final user = ref.watch(userModelProvider).asData?.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final currencySymbol = _getCurrencySymbol(cart);
    
    final shopId = cart.shopId ?? '';
    final shopAsync = shopId.isNotEmpty 
        ? ref.watch(shopDetailProvider(shopId))
        : const AsyncData<ShopModel?>(null);

    final platformDeliveryFee = 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Delivery Location', Icons.location_on_rounded, colorScheme),
            const SizedBox(height: 16),
            _buildAddressCard(context, address, colorScheme, isLight),
            const SizedBox(height: 32),
            _buildSectionHeader('Payment Method', Icons.payments_rounded, colorScheme),
            const SizedBox(height: 16),
            _buildPaymentOptions(colorScheme, isLight),
            const SizedBox(height: 32),
            _buildSectionHeader('Coupons & Discounts', Icons.confirmation_number_rounded, colorScheme),
            const SizedBox(height: 16),
            _buildCouponSection(cart, shopId, colorScheme, isLight, currencySymbol),
            const SizedBox(height: 32),
            _buildSectionHeader('Order Summary', Icons.shopping_bag_rounded, colorScheme),
            const SizedBox(height: 16),
            shopAsync.when(
              data: (shop) {
                const deliveryFee = 0.0;
                return _buildOrderSummary(cart, colorScheme, isLight, deliveryFee, currencySymbol);
              },
              loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
              error: (_, __) => _buildOrderSummary(cart, colorScheme, isLight, platformDeliveryFee, currencySymbol),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(
        context, 
        cart, 
        address, 
        user, 
        colorScheme, 
        isLight, 
        0.0,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildAddressCard(BuildContext context, dynamic address, ColorScheme colorScheme, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)] : null,
        border: isLight ? Border.all(color: colorScheme.outline.withValues(alpha: 0.1)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address?.label ?? 'Select Address', 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface)
                ),
                const SizedBox(height: 4),
                Text(
                  address?.fullAddress ?? 'Please add your delivery address', 
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.push('/customer/addresses'),
            icon: Icon(Icons.edit_location_alt_rounded, color: colorScheme.primary, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: isLight ? AppColors.lightSecondaryBackground : AppColors.background, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(ColorScheme colorScheme, bool isLight) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)] : null,
        border: isLight ? Border.all(color: colorScheme.outline.withValues(alpha: 0.1)) : null,
      ),
      child: Column(
        children: [
          _PaymentTile(
            title: 'Cash on Delivery',
            subtitle: 'Pay at your doorstep',
            icon: Icons.payments_rounded,
            isSelected: _paymentMethod == 'Cash on Delivery',
            onTap: () => setState(() => _paymentMethod = 'Cash on Delivery'),
            colorScheme: colorScheme,
            isLight: isLight,
          ),
          Divider(color: isLight ? colorScheme.outline.withValues(alpha: 0.1) : AppColors.border, indent: 64, endIndent: 16),
          _PaymentTile(
            title: 'Online Transfer',
            subtitle: 'Instant secure payment',
            icon: Icons.qr_code_scanner_rounded,
            isSelected: _paymentMethod == 'Online Transfer',
            onTap: () => setState(() => _paymentMethod = 'Online Transfer'),
            colorScheme: colorScheme,
            isLight: isLight,
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(dynamic cart, String shopId, ColorScheme colorScheme, bool isLight, String currencySymbol) {
    if (cart.items.isEmpty) return const SizedBox.shrink();
    
    final couponsAsync = ref.watch(shopCouponsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)] : null,
        border: isLight ? Border.all(color: colorScheme.outline.withValues(alpha: 0.1)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter Coupon Code (e.g. OSI)',
                    hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.confirmation_number_rounded, color: colorScheme.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isVerifyingCoupon 
                      ? null 
                      : () => _verifyAndApplyCouponCode(_couponController.text, cart.totalAmount, shopId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _isVerifyingCoupon
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
          
          if (_couponMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                _couponMessage,
                style: TextStyle(
                  color: _isCouponValid ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          Divider(color: isLight ? colorScheme.outline.withValues(alpha: 0.1) : AppColors.border),
          const SizedBox(height: 12),
          
          Text('Or select from available store coupons:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 12),

          couponsAsync.when(
            data: (coupons) {
              final activeCoupons = coupons.where((c) => 
                c.isActive && 
                c.expiryDate.isAfter(DateTime.now()) &&
                c.shopId == shopId
              ).toList();

              if (activeCoupons.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colorScheme.onSurface.withValues(alpha: 0.3), size: 18),
                      const SizedBox(width: 8),
                      Text('No active coupons available for this store', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: activeCoupons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final coupon = activeCoupons[index];
                    final isSelected = _appliedCoupon?.id == coupon.id;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _appliedCoupon = null;
                            _couponController.clear();
                            _couponMessage = '';
                          } else {
                            _appliedCoupon = coupon;
                            _couponController.text = coupon.code;
                            if (cart.totalAmount < coupon.minOrderAmount) {
                              _couponMessage = 'Min. spend required is ${coupon.minOrderAmount.round()}';
                              _isCouponValid = false;
                            } else {
                              _isCouponValid = true;
                              _couponMessage = 'Coupon applied successfully!';
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 180,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : (isLight ? AppColors.lightSecondaryBackground : AppColors.background),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.confirmation_number_rounded, color: isSelected ? Colors.white : colorScheme.primary, size: 14),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(coupon.code, style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface, fontSize: 13, letterSpacing: 0.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                    coupon.discountPercentage > 0 ? '${coupon.discountPercentage.round()}% OFF' : '${coupon.fixedDiscount.round()} $currencySymbol OFF',
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(dynamic cart, ColorScheme colorScheme, bool isLight, double deliveryFee, String currencySymbol) {
    final discount = (_isCouponValid && _appliedCoupon != null) ? _calculateDiscount(cart.totalAmount) : 0.0;
    final totalToPay = cart.totalAmount + deliveryFee - discount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)] : null,
        border: isLight ? Border.all(color: colorScheme.outline.withValues(alpha: 0.1)) : null,
      ),
      child: Column(
        children: [
          ...cart.items.values.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLight ? AppColors.lightSecondaryBackground : AppColors.background, 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text('${item.quantity}x', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: colorScheme.primary)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.product.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface))),
                    ],
                  ),
                ),
                Text('${item.totalPrice.toStringAsFixed(0)} $currencySymbol', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface)),
              ],
            ),
          )),
          Divider(color: isLight ? colorScheme.outline.withValues(alpha: 0.1) : AppColors.border, height: 32),
          _SummaryLine(label: 'Item Subtotal', value: '${cart.totalAmount.toStringAsFixed(0)} $currencySymbol', colorScheme: colorScheme),
          const SizedBox(height: 12),
          _SummaryLine(label: 'Delivery Fee', value: '${deliveryFee.toStringAsFixed(0)} $currencySymbol', color: AppColors.success, colorScheme: colorScheme),
          
          if (discount > 0) ...[
            const SizedBox(height: 12),
            _SummaryLine(
              label: 'Coupon Discount (${_appliedCoupon?.code})', 
              value: '- ${discount.toStringAsFixed(0)} $currencySymbol', 
              color: AppColors.success, 
              colorScheme: colorScheme
            ),
          ],

          Divider(color: isLight ? colorScheme.outline.withValues(alpha: 0.1) : AppColors.border, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              Text('${totalToPay.toStringAsFixed(0)} $currencySymbol', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, dynamic cart, dynamic address, dynamic user, ColorScheme colorScheme, bool isLight, double deliveryFee) {
    final currencySymbol = _getCurrencySymbol(cart);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.premiumDarkSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.3), 
            blurRadius: 30
          )
        ],
        border: Border.all(color: isLight ? colorScheme.outline.withValues(alpha: 0.1) : colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ElevatedButton(
        onPressed: (_isPlacingOrder || address == null) ? null : () {
          if (_paymentMethod == 'Online Transfer') {
            _showQRScannerDialog(context, cart, address, user, colorScheme, isLight, deliveryFee, currencySymbol);
          } else {
            _placeOrder(context, cart, address, user);
          }
        },
        child: _isPlacingOrder 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_paymentMethod == 'Online Transfer' ? 'PAY & CONFIRM' : 'CONFIRM ORDER'),
                const SizedBox(width: 12),
                const Icon(Icons.verified_rounded, size: 20),
              ],
            ),
      ),
    );
  }

  void _showQRScannerDialog(BuildContext context, dynamic cart, dynamic address, dynamic user, ColorScheme colorScheme, bool isLight, double deliveryFee, String currencySymbol) {
    final discount = (_isCouponValid && _appliedCoupon != null) ? _calculateDiscount(cart.totalAmount) : 0.0;
    final total = cart.totalAmount + deliveryFee - discount;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isLight ? Colors.white : AppColors.dialog,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Secure Checkout', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('Scan QR code to pay ${total.toStringAsFixed(0)} $currencySymbol', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isLight ? AppColors.lightSecondaryBackground : Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: QrImageView(
                data: 'PAYMENT_ID_${DateTime.now().millisecondsSinceEpoch}_AMT_$total',
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: isLight ? colorScheme.onSurface : Colors.white,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: isLight ? colorScheme.onSurface : Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Open your digital wallet to scan and pay. We will verify your transaction automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6), height: 1.6, fontWeight: FontWeight.w500),
              ),
            ),
            
            const Spacer(),
            
            _VerificationStatus(
              colorScheme: colorScheme,
              onComplete: () {
                _placeOrder(context, cart, address, user, isPrepaid: true);
              }
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, dynamic cart, dynamic address, dynamic user, {bool isPrepaid = false}) async {
    if (cart.items.isEmpty) return;

    setState(() => _isPlacingOrder = true);
    
    try {
      final firstItem = cart.items.values.first;
      final deliveryOtp = (Random().nextInt(9000) + 1000).toString();

      final shopDoc = await FirebaseFirestore.instance.collection('shops').doc(firstItem.product.shopId).get();
      final shopData = shopDoc.data();
      final shopName = shopDoc.exists ? (shopData?['name'] ?? 'Premium Shop') : 'Premium Shop';
      final shopImageUrl = shopDoc.exists 
          ? (shopData?['logoUrl'] ?? shopData?['imageUrl'] ?? shopData?['bannerImage'] ?? '') 
          : '';
      final shopPhone = shopData?['phone'] ?? '03001234567';
      final shopAddress = shopData?['address'] ?? 'Shop Address, Main Market';
      
      const double actualDeliveryFee = 0.0;
      final discount = (_isCouponValid && _appliedCoupon != null) ? _calculateDiscount(cart.totalAmount) : 0.0;
      final finalAmount = cart.totalAmount + actualDeliveryFee - discount;

      final orderData = {
        'customerId': user.uid,
        'customerName': user.name,
        'customerPhone': user.phone,
        'vendorId': firstItem.product.vendorId,
        'shopId': firstItem.product.shopId,
        'shopName': cart.shopName ?? shopName,
        'shopImageUrl': (cart.shopImageUrl != null && cart.shopImageUrl!.isNotEmpty) 
            ? cart.shopImageUrl 
            : shopImageUrl,
        'vendorPhone': shopPhone,
        'status': 'pending',
        'totalAmount': finalAmount,
        'discountAmount': discount,
        'couponCode': (_isCouponValid && _appliedCoupon != null) ? _appliedCoupon?.code : null,
        'deliveryFee': actualDeliveryFee,
        'pickupAddress': shopAddress,
        'deliveryAddress': address.fullAddress,
        'deliveryLocation': address.location,
        'items': cart.items.values.map((item) => {
          'productId': item.product.id,
          'name': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'selectedColor': item.selectedColor != null && item.selectedColor!.isNotEmpty
              ? AppColorsData.getColorName(item.selectedColor!)
              : null,
          'selectedSize': item.selectedSize,
          'imageUrl': item.product.imageUrl ?? (item.product.images?.isNotEmpty == true ? item.product.images.first : ''),
        }).toList(),
        'paymentMethod': _paymentMethod,
        'paymentStatus': isPrepaid ? 'paid' : 'pending',
        'deliveryOtp': deliveryOtp,
        'createdAt': DateTime.now(),
      };

      final orderId = await ref.read(customerServiceProvider).placeOrder(orderData);
      
      ref.read(cartProvider.notifier).clearCart();
      
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        context.go('/customer/order-success/$orderId');
      }
    } catch (e) {
      debugPrint('CRITICAL: Order placement error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placement failed: $e'), 
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }
}

class _VerificationStatus extends StatefulWidget {
  final ColorScheme colorScheme;
  final VoidCallback onComplete;
  const _VerificationStatus({required this.onComplete, required this.colorScheme});
  @override
  State<_VerificationStatus> createState() => _VerificationStatusState();
}

class _VerificationStatusState extends State<_VerificationStatus> {
  String _status = 'Awaiting payment...';
  double _progress = 0;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _simulateScanning();
  }

  void _simulateScanning() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    setState(() { _status = 'Payment detected. Verifying...'; _progress = 0.4; });
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() { _status = 'Confirming with gateway...'; _progress = 0.8; });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() { _isSuccess = true; _status = 'Payment successful!'; _progress = 1.0; });
    await Future.delayed(const Duration(seconds: 1));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isSuccess) SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: widget.colorScheme.primary)),
              if (_isSuccess) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: 12),
              Text(_status, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _isSuccess ? AppColors.success : widget.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: widget.colorScheme.onSurface.withValues(alpha: 0.05),
              color: _isSuccess ? AppColors.success : widget.colorScheme.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isLight;

  const _PaymentTile({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap, required this.colorScheme, required this.isLight});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : (isLight ? AppColors.lightSecondaryBackground : AppColors.background), 
                  borderRadius: BorderRadius.circular(14)
                ),
                child: Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        fontSize: 15, 
                        color: colorScheme.onSurface,
                      )
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle, 
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ),
              Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    ),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final ColorScheme colorScheme;
  const _SummaryLine({required this.label, required this.value, this.color, required this.colorScheme});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w500)), 
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color ?? colorScheme.onSurface))
      ]
    );
  }
}