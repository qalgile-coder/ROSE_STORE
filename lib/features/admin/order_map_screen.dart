import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';
import '../../models/order_model.dart';

class OrderMapScreen extends ConsumerStatefulWidget {
  const OrderMapScreen({super.key});

  @override
  ConsumerState<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends ConsumerState<OrderMapScreen> {
  GoogleMapController? _mapController;
  
  // مركز افتراضي ذكي (مثلاً الخرطوم كمركز رئيسي، ويمكن توسيعه لمصر والسعودية تلقائياً حسب الطلبات)
  static const LatLng _defaultCenter = LatLng(15.5007, 32.5599);

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Pulse Map - نطاق العمل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ordersAsync.when(
        data: (orders) {
          final markers = _buildGoogleMarkers(orders);
          
          // تحديد أول نقطة طلب أو الرجوع للمركز الافتراضي
          LatLng initialTarget = _defaultCenter;
          if (orders.isNotEmpty) {
            final firstValid = orders.firstWhere(
              (o) => o.deliveryLocation != null && o.deliveryLocation!.latitude.isFinite,
              orElse: () => orders.first,
            );
            if (firstValid.deliveryLocation != null) {
              initialTarget = LatLng(
                firstValid.deliveryLocation!.latitude, 
                firstValid.deliveryLocation!.longitude
              );
            }
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 12.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('خطأ في تحميل الخريطة: $e')),
      ),
    );
  }

  Set<Marker> _buildGoogleMarkers(List<OrderModel> orders) {
    Set<Marker> markers = {};

    for (var order in orders) {
      if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) {
        continue;
      }

      final loc = order.deliveryLocation;
      if (loc != null && loc.latitude.isFinite && loc.longitude.isFinite) {
        final lat = loc.latitude;
        final lng = loc.longitude;

        markers.add(
          Marker(
            markerId: MarkerId(order.id ?? DateTime.now().toIso8601String()),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: 'طلب #${order.id ?? "جديد"}',
              snippet: 'الحالة: ${order.status.name}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getStatusHue(order.status)),
          ),
        );
      }
    }

    return markers;
  }

  double _getStatusHue(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return BitmapDescriptor.hueOrange;
      case OrderStatus.preparing: return BitmapDescriptor.hueAzure;
      case OrderStatus.confirmed: return BitmapDescriptor.hueGreen;
      case OrderStatus.outForDelivery: return BitmapDescriptor.hueViolet;
      default: return BitmapDescriptor.hueRed;
    }
  }
}