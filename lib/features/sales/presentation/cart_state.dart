import 'package:equatable/equatable.dart';

import '../../../../domain/models/cart_line.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/product.dart';

/// طرق الدفع المدعومة.
const List<String> kPaymentMethods = ['نقدي', 'محفظة', 'تحويل بنكي', 'آجل'];

/// حالة السلة أثناء عملية البيع.
class CartState extends Equatable {
  const CartState({
    this.lines = const [],
    this.discount = 0,
    this.paymentMethod = 'نقدي',
    this.selectedCustomer,
    this.note = '',
    this.completing = false,
  });

  final List<CartLine> lines;
  final double discount;
  final String paymentMethod;
  final Customer? selectedCustomer;
  final String note;
  final bool completing;

  bool get isEmpty => lines.isEmpty;

  /// إجمالي عدد القطع/الكميات في السلة.
  double get totalQuantity =>
      lines.fold(0, (sum, line) => sum + line.quantity);

  /// مجموع أسعار السطور (قبل الخصم).
  double get subtotal => lines.fold(0, (sum, line) => sum + line.subtotal);

  /// الإجمالي النهائي بعد الخصم.
  double get total => (subtotal - discount).clamp(0, double.infinity);

  /// الكمية المتبقية القابلة للبيع من صنف (بعد حساب ما بالسلة).
  double availableStockOf(Product product) {
    final inCart = lines
        .where((l) => l.product.id == product.id)
        .fold(0.0, (sum, l) => sum + l.quantity);
    return (product.stock - inCart).clamp(0, double.infinity);
  }

  CartState copyWith({
    List<CartLine>? lines,
    double? discount,
    String? paymentMethod,
    Customer? selectedCustomer,
    String? note,
    bool? completing,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      note: note ?? this.note,
      completing: completing ?? this.completing,
    );
  }

  @override
  List<Object?> get props => [
        lines,
        discount,
        paymentMethod,
        selectedCustomer,
        note,
        completing,
      ];
}
