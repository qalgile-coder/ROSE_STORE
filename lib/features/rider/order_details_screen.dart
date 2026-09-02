import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:http/http.dart' as http;
import '../../core/providers.dart';
import '../../models/order_model.dart';
import '../../theme/app_colors.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrdersAsync = ref.watch(activeRiderOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Task Detail', style: const TextStyle(fontWeight: FontWeight.w900)),
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
      ),
      body: activeOrdersAsync.when(
        data: (orders) {
          final order = orders.firstWhere((o) => o.id == orderId, 
              orElse: () => throw Exception('Order not found'));
          
          return Column(
            children: [
              // LIVE TRACKING MAP AREA
              SizedBox(
                height: 250,
                child: _OSMMap(order: order),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusTimeline(currentStatus: order.status),
                      const SizedBox(height: 32),
                      
                      _SectionHeader(title: 'PICKUP', color: AppColors.rider),
                      const SizedBox(height: 12),
                      _InfoCard(
                        orderId: order.id,
                        name: order.shopName,
                        address: order.pickupAddress,
                        phone: order.vendorPhone,
                        icon: Icons.storefront_rounded,
                        accentColor: AppColors.rider,
                        colorScheme: colorScheme,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _SectionHeader(title: 'DELIVERY', color: AppColors.success),
                      const SizedBox(height: 12),
                      _InfoCard(
                        orderId: order.id,
                        name: order.customerName,
                        address: order.deliveryAddress,
                        phone: order.customerPhone,
                        icon: Icons.person_rounded,
                        accentColor: AppColors.success,
                        colorScheme: colorScheme,
                      ),
                      
                      const SizedBox(height: 32),
                      _SectionHeader(title: 'ORDER SUMMARY', color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${item['name']} x${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                  Text('Rs ${item['price']}', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                                ],
                              ),
                            )),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Colors.white10),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Earnings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                Text('Rs ${order.deliveryFee}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.success)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      bottomSheet: activeOrdersAsync.when(
        data: (orders) {
          final order = orders.firstWhere((o) => o.id == orderId);
          return _ActionPanel(order: order, ref: ref);
        },
        loading: () => const SizedBox.shrink(),
        error: (e, s) => const SizedBox.shrink(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 2))]);
}

class _OSMMap extends StatefulWidget {
  final OrderModel order;
  const _OSMMap({required this.order});

  @override
  State<_OSMMap> createState() => _OSMMapState();
}

class _OSMMapState extends State<_OSMMap> {
  List<latlong.LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final pickup = widget.order.pickupLocation != null 
      ? latlong.LatLng(widget.order.pickupLocation!.latitude, widget.order.pickupLocation!.longitude)
      : latlong.LatLng(33.6844, 73.0479);
      
    final delivery = widget.order.deliveryLocation != null
      ? latlong.LatLng(widget.order.deliveryLocation!.latitude, widget.order.deliveryLocation!.longitude)
      : latlong.LatLng(33.7000, 73.0600);

    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/${pickup.longitude},${pickup.latitude};${delivery.longitude},${delivery.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        final distance = data['routes'][0]['distance'] as num; // in meters

        setState(() {
          _routePoints = coordinates.map((c) => latlong.LatLng(c[1], c[0])).toList();
          _distanceKm = distance / 1000.0;
          _isLoadingRoute = false;
        });
      } else {
        setState(() {
          _routePoints = [pickup, delivery];
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      setState(() {
        _routePoints = [pickup, delivery];
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.order.pickupLocation != null 
      ? latlong.LatLng(widget.order.pickupLocation!.latitude, widget.order.pickupLocation!.longitude)
      : latlong.LatLng(33.6844, 73.0479);
      
    final delivery = widget.order.deliveryLocation != null
      ? latlong.LatLng(widget.order.deliveryLocation!.latitude, widget.order.deliveryLocation!.longitude)
      : latlong.LatLng(33.7000, 73.0600);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: pickup.latitude.isFinite ? pickup : const latlong.LatLng(33.6844, 73.0479),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.zenmartpro.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints.isNotEmpty ? _routePoints : [pickup, delivery],
                  color: AppColors.rider,
                  strokeWidth: 5,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (pickup.latitude.isFinite)
                  Marker(
                    point: pickup,
                    width: 40,
                    height: 40,
                    child: const _MapMarker(icon: Icons.storefront_rounded, color: AppColors.rider),
                  ),
                if (delivery.latitude.isFinite)
                  Marker(
                    point: delivery,
                    width: 40,
                    height: 40,
                    child: const _MapMarker(icon: Icons.location_on_rounded, color: AppColors.success),
                  ),
              ],
            ),
          ],
        ),
        if (!_isLoadingRoute)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_rounded, size: 16, color: AppColors.rider),
                  const SizedBox(width: 6),
                  Text(
                    '${_distanceKm.toStringAsFixed(1)} KM',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MapMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(width: 2, height: 4, color: color),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final OrderStatus currentStatus;
  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'status': OrderStatus.accepted, 'label': 'Accepted'},
      {'status': OrderStatus.reachedVendor, 'label': 'Reached'},
      {'status': OrderStatus.pickedUp, 'label': 'Picked Up'},
      {'status': OrderStatus.outForDelivery, 'label': 'On Way'},
      {'status': OrderStatus.delivered, 'label': 'Delivered'},
    ];

    return Row(
      children: steps.map((step) {
        final isActive = OrderStatus.values.indexOf(currentStatus) >= OrderStatus.values.indexOf(step['status'] as OrderStatus);
        
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.rider : Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive ? AppColors.rider : Colors.white24,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String orderId;
  final String name;
  final String address;
  final String phone;
  final IconData icon;
  final Color accentColor;
  final ColorScheme colorScheme;

  const _InfoCard({
    required this.orderId,
    required this.name,
    required this.address,
    required this.phone,
    required this.icon,
    required this.accentColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(address, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.call_rounded,
                label: 'CALL',
                onTap: () => launchUrl(Uri.parse('tel:$phone')),
                color: accentColor,
              ),
              const SizedBox(width: 12),
              _ActionBtn(
                icon: Icons.chat_bubble_rounded,
                label: 'CHAT',
                onTap: () => context.push('/chat/$orderId/$name'),
                color: accentColor,
              ),
              const Spacer(),
              _ActionBtn(
                icon: Icons.near_me_rounded,
                label: 'NAVIGATE',
                onTap: () => launchUrl(Uri.parse('google.navigation:q=$address')),
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({required this.icon, required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final OrderModel order;
  final WidgetRef ref;

  const _ActionPanel({required this.order, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String buttonText = 'Next Step';
    OrderStatus nextStatus = order.status;

    switch (order.status) {
      case OrderStatus.accepted:
        buttonText = 'I HAVE REACHED VENDOR';
        nextStatus = OrderStatus.reachedVendor;
        break;
      case OrderStatus.reachedVendor:
        buttonText = 'I HAVE PICKED UP ORDER';
        nextStatus = OrderStatus.pickedUp;
        break;
      case OrderStatus.pickedUp:
        buttonText = 'OUT FOR DELIVERY';
        nextStatus = OrderStatus.outForDelivery;
        break;
      case OrderStatus.outForDelivery:
        buttonText = 'MARK AS DELIVERED';
        nextStatus = OrderStatus.delivered;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1))),
      ),
      child: ElevatedButton(
        onPressed: () {
          if (nextStatus == OrderStatus.delivered) {
            _showOtpDialog(context, order);
          } else {
            ref.read(orderServiceProvider).updateStatus(order.id, nextStatus);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rider,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(buttonText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  void _showOtpDialog(BuildContext context, OrderModel order) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Verify Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ask customer for the 4-digit code.', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 12, color: AppColors.rider),
              decoration: InputDecoration(
                hintText: '0000',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: TextStyle(color: Colors.white.withValues(alpha: 0.4)))),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text == order.deliveryOtp) {
                await ref.read(orderServiceProvider).updateStatus(order.id, OrderStatus.delivered);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Go back to dashboard
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Verification Code'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rider),
            child: const Text('VERIFY & COMPLETE'),
          ),
        ],
      ),
    );
  }
}
