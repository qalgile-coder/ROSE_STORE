import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../theme/app_colors.dart';
import '../../services/pdf_service.dart';

class CustomerOrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const CustomerOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    final bgColor = isLight ? AppColors.lightBackground : AppColors.premiumDarkBackground;
    final cardColor = isLight ? AppColors.lightSurface : AppColors.premiumDarkSurface;
    final primaryColor = isLight ? AppColors.lightPrimary : AppColors.premiumDarkPrimary;
    final textColor = isLight ? AppColors.lightTextPrimary : AppColors.premiumDarkTextPrimary;
    final secondaryTextColor = isLight ? AppColors.lightTextSecondary : AppColors.premiumDarkTextSecondary;
    final dividerColor = isLight ? AppColors.lightBorder : AppColors.premiumDarkDivider;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Order Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          StreamBuilder<OrderModel?>(
            stream: ref.read(customerServiceProvider).getOrderStream(orderId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: Icon(Icons.download_rounded, size: 22, color: primaryColor),
                  onPressed: () => PdfService.generateOrderInvoice(snapshot.data!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<OrderModel?>(
        stream: ref.read(customerServiceProvider).getOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }
          final order = snapshot.data;
          if (order == null) return Center(child: Text('Order not found', style: TextStyle(color: secondaryTextColor)));

          return Column(
            children: [
              SizedBox(
                height: 220,
                child: _GoogleOrderMap(order: order, primaryColor: primaryColor),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusTracker(context, order.status, cardColor, textColor, secondaryTextColor, primaryColor, dividerColor, isLight),
                      
                      if (order.status != OrderStatus.delivered && 
                          order.status != OrderStatus.cancelled && 
                          order.status != OrderStatus.rejected) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08), 
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DELIVERY OTP', 
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: primaryColor, letterSpacing: 1.5)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Give this to your rider', 
                                    style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 15)],
                                ),
                                child: Text(
                                  order.deliveryOtp ?? '----', 
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: AppColors.premiumDarkBackground, letterSpacing: 4)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Delivery Address', icon: Icons.location_on_rounded, primaryColor: primaryColor, textColor: textColor),
                      const SizedBox(height: 16),
                      _InfoCard(
                        cardColor: cardColor,
                        dividerColor: dividerColor,
                        isLight: isLight,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.home_rounded, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Delivery Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor)),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.deliveryAddress, 
                                    style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w500)
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (order.riderId != null) ...[
                        const SizedBox(height: 32),
                        _SectionHeader(title: 'Rider Details', icon: Icons.directions_bike_rounded, primaryColor: primaryColor, textColor: textColor),
                        const SizedBox(height: 16),
                        _buildRiderCard(context, order, cardColor, textColor, secondaryTextColor, primaryColor, bgColor),
                      ],

                      const SizedBox(height: 32),
                      _SectionHeader(title: 'Order Summary', icon: Icons.receipt_long_rounded, primaryColor: primaryColor, textColor: textColor),
                      const SizedBox(height: 16),
                      _buildOrderSummary(order, cardColor, textColor, secondaryTextColor, primaryColor, dividerColor, isLight, bgColor),
                      const SizedBox(height: 40),
                      _buildActionButtons(context, ref, order, primaryColor, isLight, cardColor, textColor, secondaryTextColor, dividerColor),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusTracker(
    BuildContext context, 
    OrderStatus status, 
    Color cardColor, 
    Color textColor, 
    Color secondaryTextColor, 
    Color primaryColor, 
    Color dividerColor, 
    bool isLight
  ) {
    return _InfoCard(
      cardColor: cardColor,
      dividerColor: dividerColor,
      isLight: isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.name.toUpperCase(),
                  style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _CustomProgressBar(status: status, primaryColor: primaryColor, bgColor: dividerColor),
        ],
      ),
    );
  }

  Widget _buildRiderCard(
    BuildContext context, 
    OrderModel order, 
    Color cardColor, 
    Color textColor, 
    Color secondaryTextColor, 
    Color primaryColor, 
    Color bgColor
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(order.riderId).snapshots(),
      builder: (context, snapshot) {
        final riderData = snapshot.data?.data() as Map<String, dynamic>?;
        final riderName = riderData?['name'] ?? 'Assigned Rider';
        final riderPhone = riderData?['phone'] ?? '';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(riderName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
                    const SizedBox(height: 2),
                    Text('Your delivery partner', style: TextStyle(color: secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (riderPhone.isNotEmpty)
                _SmallRoundBtn(
                  icon: Icons.phone_rounded,
                  color: primaryColor,
                  onTap: () => launchUrl(Uri.parse('tel:$riderPhone')),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(
    OrderModel order, 
    Color cardColor, 
    Color textColor, 
    Color secondaryTextColor, 
    Color primaryColor, 
    Color dividerColor, 
    bool isLight,
    Color bgColor
  ) {
    return _InfoCard(
      cardColor: cardColor,
      dividerColor: dividerColor,
      isLight: isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor)),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item['quantity']}x ${item['name']}', 
                    style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w600)
                  ),
                ),
                Text(
                  '\$${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}', 
                  style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800)
                ),
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: dividerColor),
          ),
          _SummaryLine(label: 'Subtotal', value: '\$${order.subtotal.toStringAsFixed(2)}', textColor: textColor, secondaryTextColor: secondaryTextColor),
          const SizedBox(height: 8),
          _SummaryLine(label: 'Delivery Fee', value: '\$${order.deliveryFee.toStringAsFixed(2)}', textColor: textColor, secondaryTextColor: secondaryTextColor),
          if (order.discount > 0) ...[
            const SizedBox(height: 8),
            _SummaryLine(label: 'Discount', value: '-\$${order.discount.toStringAsFixed(2)}', color: Colors.green, textColor: textColor, secondaryTextColor: secondaryTextColor),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: dividerColor),
          ),
          _SummaryLine(
            label: 'Total Amount', 
            value: '\$${order.total.toStringAsFixed(2)}', 
            color: primaryColor, 
            textColor: textColor, 
            secondaryTextColor: secondaryTextColor
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, 
    WidgetRef ref, 
    OrderModel order, 
    Color primaryColor, 
    bool isLight,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color dividerColor
  ) {
    if (order.status == OrderStatus.delivered) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => _showReviewDialog(context, ref, order, isLight, primaryColor, cardColor, textColor, secondaryTextColor),
          child: const Text('Rate Order & Products', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      );
    }
    
    if (order.status == OrderStatus.pending) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () async {
            await ref.read(customerServiceProvider).cancelOrder(order.id);
          },
          child: const Text('Cancel Order', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 15)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showReviewDialog(
    BuildContext context, 
    WidgetRef ref, 
    OrderModel order, 
    bool isLight, 
    Color primary,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor
  ) {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialogContent(
        order: order, 
        isLight: isLight, 
        primary: primary,
        cardColor: cardColor,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        ref: ref,
      ),
    );
  }
}

class _ReviewDialogContent extends StatefulWidget {
  final OrderModel order;
  final bool isLight;
  final Color primary;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final WidgetRef ref;

  const _ReviewDialogContent({
    required this.order,
    required this.isLight,
    required this.primary,
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.ref,
  });

  @override
  State<_ReviewDialogContent> createState() => _ReviewDialogContentState();
}

class _ReviewDialogContentState extends State<_ReviewDialogContent> {
  int shopRating = 5;
  final Map<String, int> productRatings = {};
  final TextEditingController reviewController = TextEditingController();
  bool isSubmitting = false;
  bool isDeleting = false;
  ReviewModel? existingReview;

  @override
  void initState() {
    super.initState();
    for (var item in widget.order.items) {
      productRatings[item['productId']] = 5;
    }
    _loadExistingReview();
  }

  Future<void> _loadExistingReview() async {
    final review = await widget.ref.read(customerServiceProvider).getExistingReview(widget.order.id);
    if (review != null && mounted) {
      setState(() {
        existingReview = review;
        shopRating = review.rating.toInt();
        reviewController.text = review.review ?? '';
        for (var pr in review.productRatings) {
          productRatings[pr['productId']] = pr['rating'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.all(24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Rate Your Order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: widget.textColor)),
          if (existingReview != null)
            IconButton(
              icon: isDeleting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              onPressed: isDeleting ? null : () async {
                setState(() => isDeleting = true);
                try {
                  await widget.ref.read(customerServiceProvider).deleteReview(widget.order.id, existingReview!.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) setState(() => isDeleting = false);
                }
              },
            ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Store Experience:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: widget.textColor)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => InkWell(
                  onTap: (isDeleting || isSubmitting) ? null : () => setState(() => shopRating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star_rounded, 
                      color: index < shopRating ? AppColors.warning : (widget.isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05)), 
                      size: 32
                    ),
                  ),
                )),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1),
              ),
              Text('Rate Products:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: widget.textColor)),
              const SizedBox(height: 16),
              ...widget.order.items.map((item) {
                final pid = item['productId'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isLight ? Colors.black.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.textColor)),
                      const SizedBox(height: 8),
                      FittedBox(
                        child: Row(
                          children: List.generate(5, (index) => InkWell(
                            onTap: (isDeleting || isSubmitting) ? null : () => setState(() => productRatings[pid] = index + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.star_rounded, color: index < (productRatings[pid] ?? 5) ? AppColors.warning : (widget.isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05)), size: 24),
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                maxLines: 4,
                enabled: !isDeleting && !isSubmitting,
                style: TextStyle(color: widget.textColor, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about the service and products...',
                  hintStyle: TextStyle(color: widget.secondaryTextColor, fontSize: 13),
                  filled: true,
                  fillColor: widget.isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: (isDeleting || isSubmitting) ? null : () => Navigator.pop(context), 
                child: Text(existingReview != null ? 'CANCEL' : 'SKIP', style: TextStyle(color: widget.secondaryTextColor, fontWeight: FontWeight.w800, letterSpacing: 1))
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (isDeleting || isSubmitting) ? null : () async {
                  setState(() => isSubmitting = true);
                  try {
                    final reviewText = reviewController.text.trim();
                    final List<Map<String, dynamic>> productRatingsList = productRatings.entries.map((e) => {
                      'productId': e.key,
                      'rating': e.value,
                      'review': reviewText,
                    }).toList();
        
                    await widget.ref.read(customerServiceProvider).submitReview(
                      orderId: widget.order.id,
                      shopId: widget.order.shopId,
                      riderId: widget.order.riderId,
                      customerName: widget.order.customerName,
                      rating: shopRating.toDouble(),
                      review: reviewText,
                      productRatings: productRatingsList,
                      oldRating: existingReview?.rating,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Submission failed. Please check your permissions or try again.'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56), 
                  backgroundColor: widget.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: isSubmitting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(existingReview != null ? 'UPDATE REVIEW' : 'SUBMIT REVIEW', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomProgressBar extends StatelessWidget {
  final OrderStatus status;
  final Color primaryColor;
  final Color bgColor;
  const _CustomProgressBar({required this.status, required this.primaryColor, required this.bgColor});

  double _getVal() {
    switch (status) {
      case OrderStatus.pending: return 0.1;
      case OrderStatus.preparing: return 0.3;
      case OrderStatus.confirmed: return 0.45;
      case OrderStatus.accepted: return 0.6;
      case OrderStatus.reachedVendor: return 0.7;
      case OrderStatus.pickedUp: return 0.8;
      case OrderStatus.outForDelivery: return 0.9;
      case OrderStatus.delivered: return 1.0;
      default: return 0.1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _getVal(),
            minHeight: 8,
            backgroundColor: bgColor,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StepDot(label: 'Placed', active: true, primary: primaryColor),
            _StepDot(label: 'Preparing', active: _getVal() >= 0.3, primary: primaryColor),
            _StepDot(label: 'Rider', active: _getVal() >= 0.6, primary: primaryColor),
            _StepDot(label: 'Delivered', active: _getVal() == 1.0, primary: primaryColor),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool active;
  final Color primary;
  const _StepDot({required this.label, required this.active, required this.primary});
  @override
  Widget build(BuildContext context) => Text(
    label, 
    style: TextStyle(
      fontSize: 10, 
      fontWeight: FontWeight.w900, 
      color: active ? primary : AppColors.textDisabled,
      letterSpacing: 0.5
    )
  );
}

class _GoogleOrderMap extends StatelessWidget {
  final OrderModel order;
  final Color primaryColor;
  const _GoogleOrderMap({required this.order, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final pickupRaw = order.pickupLocation;
    final deliveryRaw = order.deliveryLocation;
    
    final LatLng pickup = (pickupRaw != null && pickupRaw.latitude.isFinite) 
        ? LatLng(pickupRaw.latitude, pickupRaw.longitude) 
        : const LatLng(33.6844, 73.0479);
        
    final LatLng delivery = (deliveryRaw != null && deliveryRaw.latitude.isFinite) 
        ? LatLng(deliveryRaw.latitude, deliveryRaw.longitude) 
        : const LatLng(33.7000, 73.0600);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: delivery, zoom: 14.0),
      markers: {
        Marker(
          markerId: const MarkerId('pickup_marker'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Store Location'),
        ),
        Marker(
          markerId: const MarkerId('delivery_marker'),
          position: delivery,
          infoWindow: const InfoWindow(title: 'Delivery Location'),
        ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final Color textColor;
  const _SectionHeader({required this.title, required this.icon, required this.primaryColor, required this.textColor});
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 18, color: primaryColor), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.2))]);
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  final Color cardColor;
  final Color dividerColor;
  final bool isLight;
  const _InfoCard({required this.child, required this.cardColor, required this.dividerColor, required this.isLight});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(24), 
    decoration: BoxDecoration(
      color: cardColor, 
      borderRadius: BorderRadius.circular(32),
      boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)] : null,
      border: isLight ? Border.all(color: dividerColor) : Border.all(color: dividerColor.withOpacity(0.3)),
    ), 
    child: child
  );
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final Color textColor;
  final Color secondaryTextColor;
  const _SummaryLine({required this.label, required this.value, this.color, required this.textColor, required this.secondaryTextColor});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: secondaryTextColor, fontSize: 14, fontWeight: FontWeight.w600)), Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color ?? textColor))]);
}

class _SmallRoundBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallRoundBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)));
}