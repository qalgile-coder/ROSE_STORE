import 'product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  final String? selectedColor; // اللون المختار للمنتج
  final String? selectedSize;  // الحجم المختار للمنتج

  CartItem({
    required this.product, 
    this.quantity = 1,
    this.selectedColor,
    this.selectedSize,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    ProductModel? product, 
    int? quantity,
    String? selectedColor,
    String? selectedSize,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
    );
  }
}

class CartModel {
  final Map<String, CartItem> items;
  final String? shopId;
  final String? shopName;
  final String? shopImageUrl;

  CartModel({
    this.items = const {},
    this.shopId,
    this.shopName,
    this.shopImageUrl,
  });

  double get totalAmount {
    double total = 0.0;
    items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  int get itemCount => items.length;

  int get totalQuantity {
    int count = 0;
    items.forEach((key, cartItem) {
      count += cartItem.quantity;
    });
    return count;
  }

  CartModel copyWith({
    Map<String, CartItem>? items,
    String? shopId,
    String? shopName,
    String? shopImageUrl,
  }) {
    return CartModel(
      items: items ?? this.items,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopImageUrl: shopImageUrl ?? this.shopImageUrl,
    );
  }
}