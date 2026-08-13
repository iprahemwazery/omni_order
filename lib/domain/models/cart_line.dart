import 'product.dart';

/// سطر داخل سلة المشتريات الحالية.
class CartLine {
  final Product product;
  final double quantity;

  const CartLine({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  CartLine copyWith({Product? product, double? quantity}) {
    return CartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
