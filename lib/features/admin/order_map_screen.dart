import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../models/order_model.dart';

class OrderMapScreen extends ConsumerWidget {
  const OrderMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Pulse Map', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ordersAsync.when(
        data: (orders) {
          final markers = _buildMarkers(orders, colorScheme);
          
          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(33.6844, 73.0479), // Default to Islamabad center
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zenmartpro.app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading map: $e')),
      ),
    );
  }

  List<Marker> _buildMarkers(List<OrderModel> orders, ColorScheme colorScheme) {
    return orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).map((order) {
      final loc = order.deliveryLocation;
      final lat = (loc != null && loc.latitude.isFinite) ? loc.latitude : 33.6844;
      final lng = (loc != null && loc.longitude.isFinite) ? loc.longitude : 73.0479;

      return Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            // Show mini info
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.preparing: return Colors.blue;
      case OrderStatus.confirmed: return Colors.green;
      case OrderStatus.outForDelivery: return Colors.purple;
      default: return Colors.grey;
    }
  }
}
