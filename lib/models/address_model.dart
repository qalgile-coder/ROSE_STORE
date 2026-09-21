import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String label; // e.g., Home, Work, Other
  final String fullAddress;
  final String city;
  final GeoPoint? location;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.city,
    this.location,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(Map<String, dynamic> data, String id) {
    return AddressModel(
      id: id,
      label: data['label'] ?? 'Home',
      fullAddress: data['fullAddress'] ?? '',
      city: data['city'] ?? '',
      location: data['location'],
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'fullAddress': fullAddress,
      'city': city,
      'location': location,
      'isDefault': isDefault,
    };
  }
}
