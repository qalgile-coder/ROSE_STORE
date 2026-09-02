import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';

class CacheService {
  static const String _productsBoxName = 'cached_products';
  static const String _shopsBoxName = 'cached_shops';
  static const String _userBoxName = 'cached_user';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_productsBoxName);
    await Hive.openBox(_shopsBoxName);
    await Hive.openBox(_userBoxName);
  }

  // --- Products Caching ---
  static Future<void> cacheProducts(List<ProductModel> products) async {
    final box = Hive.box(_productsBoxName);
    final data = {for (var p in products) p.id: p.toMap()};
    await box.put('all_products', jsonEncode(data));
  }

  static List<ProductModel> getCachedProducts() {
    try {
      final box = Hive.box(_productsBoxName);
      final String? rawData = box.get('all_products');
      if (rawData == null) return [];
      
      final Map<String, dynamic> decoded = jsonDecode(rawData);
      return decoded.entries.map((e) => ProductModel.fromMap(e.value, e.key)).toList();
    } catch (e) {
      debugPrint('Cache Read Error (Products): $e');
      return [];
    }
  }

  // --- Shops Caching ---
  static Future<void> cacheShops(List<ShopModel> shops) async {
    final box = Hive.box(_shopsBoxName);
    final data = {for (var s in shops) s.id: s.toMap()};
    await box.put('all_shops', jsonEncode(data));
  }

  static List<ShopModel> getCachedShops() {
    try {
      final box = Hive.box(_shopsBoxName);
      final String? rawData = box.get('all_shops');
      if (rawData == null) return [];
      
      final Map<String, dynamic> decoded = jsonDecode(rawData);
      return decoded.entries.map((e) => ShopModel.fromMap(e.value, e.key)).toList();
    } catch (e) {
      debugPrint('Cache Read Error (Shops): $e');
      return [];
    }
  }

  static Future<void> clearAll() async {
    await Hive.box(_productsBoxName).clear();
    await Hive.box(_shopsBoxName).clear();
    await Hive.box(_userBoxName).clear();
  }
}
