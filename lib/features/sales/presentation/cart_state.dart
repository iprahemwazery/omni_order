import 'package:equatable/equatable.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../domain/models/cart_line.dart';
import '../../../../domain/models/product.dart';

/// حالة السلة أثناء عملية البيع.
class CartState extends Equatable {
  const CartState({
    this.lines = const [],
    this.discount = 0,
    this.paymentMethod = PaymentMethod.cash,
    this.note = '',
    this.amountTendered = 0,
    this.cardAmount = 0,
    this.tip = 0,
    this.completing = false,
    this.orderType = 'عميل_عادي',
    this.tableName = '',
    this.customerName = '',
  });

  final List<CartLine> lines;
  final double discount;
  final String paymentMethod;
  final String note;

  /// المبلغ الذي دفعه العميل (لحساب الباقي). صفر = الصافي كاملًا.
  final double amountTendered;

  /// الجزء المدفوع بالشبكة في حالة الدفع المختلط.
  final double cardAmount;

  /// بقشيش العميل.
  final double tip;
  final bool completing;

  /// نوع البيع: 'عميل_عادي' | 'صاله' | 'دلفري'
  final String orderType;

  /// اسم التريبية (عند بيع الصاله).
  final String tableName;

  /// اسم العميل (عند البيع بالدلفري).
  final String customerName;

  bool get isEmpty => lines.isEmpty;

  /// إجمالي عدد القطع/الكميات في السلة.
  double get totalQuantity =>
      lines.fold(0, (sum, line) => sum + line.quantity);

  /// مجموع أسعار السطور (قبل الخصم).
  double get subtotal => lines.fold(0, (sum, line) => sum + line.subtotal);

  /// الإجمالي النهائي بعد الخصم.
  double get total => (subtotal - discount).clamp(0, double.infinity);

  /// الباقي للعميل إذا دفع أكثر من الصافي.
  double get changeDue =>
      (amountTendered - total).clamp(0, double.infinity);

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
    String? note,
    double? amountTendered,
    double? cardAmount,
    double? tip,
    bool? completing,
    String? orderType,
    String? tableName,
    String? customerName,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      amountTendered: amountTendered ?? this.amountTendered,
      cardAmount: cardAmount ?? this.cardAmount,
      tip: tip ?? this.tip,
      completing: completing ?? this.completing,
      orderType: orderType ?? this.orderType,
      tableName: tableName ?? this.tableName,
      customerName: customerName ?? this.customerName,
    );
  }

  @override
  List<Object?> get props => [
        lines,
        discount,
        paymentMethod,
        note,
        amountTendered,
        cardAmount,
        tip,
        completing,
        orderType,
        tableName,
        customerName,
      ];
}
