import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapUtils {
  static double calculateDistance(GeoPoint? p1, GeoPoint? p2) {
    if (p1 == null || p2 == null) return 0.0;
    
    var lat1 = p1.latitude;
    var lon1 = p1.longitude;
    var lat2 = p2.latitude;
    var lon2 = p2.longitude;
    
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
