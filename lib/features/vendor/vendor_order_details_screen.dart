import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';
import '../../core/localization.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';
import '../../services/pdf_service.dart';

class VendorOrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const VendorOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FutureBuilder<OrderModel?>(
            future: ref.read(vendorServiceProvider).getOrder(orderId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return IconButton(
                  icon: Icon(Icons.print_rounded, color: colorScheme.primary),
                  onPressed: () => PdfService.generateOrderInvoice(snapshot.data!),
                  tooltip: 'Print Invoice',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<OrderModel?>(
        stream: ref.read(vendorServiceProvider).getShopOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }
          final order = snapshot.data;
          if (order == null) {
            return Center(child: Text('Order not found', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(order.status),
                const SizedBox(height: 32),
                
                _SectionTitle(title: 'Customer Information', icon: Icons.person_rounded, primaryColor: colorScheme.primary),
                const SizedBox(height: 16),
                _InfoCard(
                  colorScheme: colorScheme,
                  isLight: isLight,
                  children: [
                    _InfoRow(label: 'Name', value: order.customerName, colorScheme: colorScheme),
                    _InfoRow(label: 'Phone', value: order.customerPhone, isPhone: true, colorScheme: colorScheme),
                    _InfoRow(label: 'Address', value: order.deliveryAddress, colorScheme: colorScheme),
                  ],
                ),
                
                const SizedBox(height: 32),
                _SectionTitle(title: 'Ordered Items', icon: Icons.shopping_bag_rounded, primaryColor: colorScheme.primary),
                const SizedBox(height: 16),
                _InfoCard(
                  colorScheme: colorScheme,
                  isLight: isLight,
                  children: [
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('x${item['quantity']}', style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Rs ${item['price'] * item['quantity']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: colorScheme.outline.withOpacity(0.1)),
                    ),
                    _InfoRow(label: 'Delivery Fee', value: 'Rs ${order.deliveryFee}', colorScheme: colorScheme),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: colorScheme.onSurface)),
                        Text(
                          'Rs ${order.totalAmount}', 
                          style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                _SectionTitle(title: 'Payment Information', icon: Icons.payments_rounded, primaryColor: colorScheme.primary),
                const SizedBox(height: 16),
                _InfoCard(
                  colorScheme: colorScheme,
                  isLight: isLight,
                  children: [
                    _InfoRow(label: 'Method', value: order.paymentMethod, colorScheme: colorScheme),
                    _InfoRow(
                      label: 'Status', 
                      value: order.paymentStatus.toUpperCase(),
                      valueColor: order.paymentStatus == 'paid' ? AppColors.success : AppColors.warning,
                      colorScheme: colorScheme,
                    ),
                    _InfoRow(label: 'Order Date', value: DateFormat('MMM dd, yyyy').format(order.createdAt), colorScheme: colorScheme),
                    _InfoRow(label: 'Order Time', value: DateFormat('hh:mm a').format(order.createdAt), colorScheme: colorScheme),
                  ],
                ),
                const SizedBox(height: 48),
                _buildActionButtons(context, ref, order, colorScheme.primary),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending: color = AppColors.warning; break;
      case OrderStatus.preparing: color = AppColors.info; break;
      case OrderStatus.confirmed: color = AppColors.success; break;
      case OrderStatus.cancelled:
      case OrderStatus.rejected: color = AppColors.error; break;
      default: color = Colors.purple;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'STATUS',
            style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, OrderModel order, Color primary) {
    if (order.status == OrderStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(context, ref, order.id, OrderStatus.cancelled),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('REJECT'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(context, ref, order.id, OrderStatus.preparing),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('ACCEPT ORDER'),
            ),
          ),
        ],
      );
    }

    if (order.status == OrderStatus.preparing) {
      return ElevatedButton(
        onPressed: () => _updateStatus(context, ref, order.id, OrderStatus.confirmed),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('MARK AS READY'),
      );
    }

    return const SizedBox.shrink();
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String id, OrderStatus status) async {
    await ref.read(orderServiceProvider).updateStatus(id, status);
    
    // Automatically determine which tab to go back to
    int targetTab = 0;
    if (status == OrderStatus.preparing) targetTab = 2;
    if (status == OrderStatus.confirmed) targetTab = 3;
    if (status == OrderStatus.cancelled) targetTab = 5;

    if (context.mounted) {
      ref.read(vendorActiveOrderTabProvider.notifier).state = targetTab;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order moved to ${status.name.toUpperCase()}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  const _SectionTitle({required this.title, required this.icon, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final ColorScheme colorScheme;
  final bool isLight;
  const _InfoCard({required this.children, required this.colorScheme, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(isLight ? 0.5 : 0.1)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPhone;
  final Color? valueColor;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.label, 
    required this.value, 
    this.isPhone = false, 
    this.valueColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: isPhone ? () => launchUrl(Uri.parse('tel:$value')) : null,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? (isPhone ? colorScheme.primary : colorScheme.onSurface),
                  decoration: isPhone ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
