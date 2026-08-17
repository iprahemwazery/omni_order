import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../domain/models/cart_line.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/held_cart.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/sale.dart';
import '../../../../domain/models/sale_item.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../customers/presentation/customers_cubit.dart';
import '../../products/presentation/products_cubit.dart';
import 'cart_state.dart';
import 'sales_cubit.dart';

/// يدير السلة الحالية: البنود، الخصم، طريقة الدفع، العميل، وإتمام البيع.
///
/// بعد نجاح البيع يُحدّث المخزون والمديونيات وسجل المبيعات من خلال إعادة
/// تحميل [ProductsCubit] و [CustomersCubit] و [SalesCubit] للحفاظ على
/// تزامن الشاشات (الرئيسية والتقارير والمبيعات السابقة).
class CartCubit extends Cubit<CartState> {
  CartCubit({
    required StoreRepository repository,
    required ProductsCubit productsCubit,
    required CustomersCubit customersCubit,
    required SalesCubit salesCubit,
  })  : _repository = repository,
        _productsCubit = productsCubit,
        _customersCubit = customersCubit,
        _salesCubit = salesCubit,
        super(const CartState());

  final StoreRepository _repository;
  final ProductsCubit _productsCubit;
  final CustomersCubit _customersCubit;
  final SalesCubit _salesCubit;

  /// يضيف صنفًا للسلة بعد التحقق من المخزون.
  String? addToCart(Product product, double quantity) {
    if (quantity <= 0) return 'اختر كمية أكبر من صفر.';
    final available = state.availableStockOf(product);
    if (quantity > available) {
      final unit = product.unit.isEmpty ? '' : ' ${product.unit}';
      return 'الكمية المتاحة من "${product.name}" هي $available$unit فقط.';
    }

    final lines = [...state.lines];
    final index = lines.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      lines[index] = lines[index].copyWith(
        quantity: lines[index].quantity + quantity,
      );
    } else {
      lines.add(CartLine(product: product, quantity: quantity));
    }
    emit(state.copyWith(lines: lines));
    return null;
  }

  void updateCartQuantity(int index, double quantity) {
    final lines = [...state.lines];
    if (quantity <= 0) {
      lines.removeAt(index);
    } else {
      final maxQty = lines[index].product.stock;
      lines[index] = lines[index].copyWith(
        quantity: quantity.clamp(0, maxQty),
      );
    }
    emit(state.copyWith(lines: lines));
  }

  void removeFromCart(int index) {
    final lines = [...state.lines]..removeAt(index);
    emit(state.copyWith(lines: lines));
  }

  void setCartDiscount(double discount) {
    emit(state.copyWith(discount: discount < 0 ? 0 : discount));
  }

  void setPaymentMethod(String method) {
    if (PaymentMethod.all.contains(method)) {
      emit(state.copyWith(paymentMethod: method));
    }
  }

  void selectCustomer(Customer? customer) {
    emit(state.copyWith(selectedCustomer: customer));
  }

  void setSaleNote(String note) {
    emit(state.copyWith(note: note));
  }

  /// المبلغ الذي دفعه العميل (لحساب الباقي).
  void setAmountTendered(double amount) {
    emit(state.copyWith(amountTendered: amount < 0 ? 0 : amount));
  }

  /// الجزء المدفوع بالشبكة في حالة الدفع المختلط.
  void setCardAmount(double amount) {
    emit(state.copyWith(cardAmount: amount < 0 ? 0 : amount));
  }

  void clearCart() => emit(const CartState());

  /// يعلّق السلة الحالية: يحفظها محليًا (SQLite) ثم يُفرّغ السلة لاستقبال
  /// عميل جديد. يعيد معرّف الفاتورة المعلقة أو null إذا كانت السلة فارغة.
  Future<int?> holdCart({String cashierName = ''}) async {
    final current = state;
    if (current.isEmpty) return null;
    final items = [
      for (final line in current.lines)
        HeldCartItem(
          heldCartId: 0,
          productId: line.product.id,
          name: line.product.name,
          price: line.product.price,
          costPrice: line.product.costPrice,
          quantity: line.quantity,
          subtotal: line.subtotal,
        ),
    ];
    final id = await _repository.holdCart(
      cart: HeldCart(
        savedAt: DateTime.now(),
        discount: current.discount,
        paymentMethod: current.paymentMethod,
        customerId: current.selectedCustomer?.id,
        note: current.note.trim(),
        cashierName: cashierName,
        itemsCount: items.length,
        total: current.total,
      ),
      items: items,
    );
    emit(const CartState());
    return id;
  }

  /// يسترجع فاتورة معلقة: يعيد بناء السلة من لقطة البنود مع التحقق من
  /// المخزون الحالي، ويحذفها من قائمة المعلقة.
  ///
  /// يعيد null عند النجاح، أو رسالة تحذير/خطأ. الأصناف المنتهية أو
  /// النافدة تُتجاهل ويُشار إليها في الرسالة.
  Future<String?> restoreHeldCart(HeldCart cart) async {
    if (cart.id == null) return 'تعذر استرجاع الفاتورة المعلقة.';
    final items = await _repository.getHeldCartItems(cart.id!);

    final lines = <CartLine>[];
    final skipped = <String>[];
    for (final item in items) {
      Product? product;
      for (final p in _productsCubit.state.products) {
        if (p.id == item.productId) {
          product = p;
          break;
        }
      }
      if (product == null || product.stock <= 0) {
        skipped.add(item.name);
        continue;
      }
      final quantity = item.quantity.clamp(0.0, product.stock);
      lines.add(CartLine(product: product, quantity: quantity));
    }
    if (lines.isEmpty) {
      return 'لا يمكن الاسترجاع: '
          '${skipped.isEmpty ? 'كل الأصناف غير متوفرة أو نَفدت.' : skipped.join('، ')}';
    }

    Customer? customer;
    if (cart.customerId != null) {
      customer = _customersCubit.state.customerById(cart.customerId!);
    }

    emit(
      CartState(
        lines: lines,
        discount: cart.discount,
        paymentMethod: PaymentMethod.all.contains(cart.paymentMethod)
            ? cart.paymentMethod
            : PaymentMethod.cash,
        selectedCustomer: customer,
        note: cart.note,
      ),
    );

    await _repository.deleteHeldCart(cart.id!);
    if (skipped.isEmpty) return null;
    return 'تم الاسترجاع، لكن هذه الأصناف نَفدت ولم تُضف: ${skipped.join('، ')}';
  }

  /// يُنهي البيع: يحفظ الفاتورة، يخصم المخزون (داخل معاملة)، يحدّث مديونية
  /// العميل، ويرجّع الفاتورة المنشأة. [cashierName] هو اسم المستخدم المسجل.
  /// [taxRate] نسبة الضريبة % (تُضاف داخل السعر — الأسعار شاملة الضريبة).
  Future<Sale?> completeSale({
    String cashierName = '',
    double taxRate = 0,
  }) async {
    final current = state;
    if (current.isEmpty) return null;

    // الضريبة مضمنة في السعر: قيمة الضريبة تُستخرج من الصافي.
    final net = current.total;
    final taxAmount = taxRate <= 0
        ? 0.0
        : net * taxRate / (100 + taxRate);

    emit(current.copyWith(completing: true));
    try {
      final items = [
        for (final line in current.lines)
          SaleItem(
            saleId: 0,
            productId: line.product.id ?? 0,
            name: line.product.name,
            price: line.product.price,
            costPrice: line.product.costPrice,
            quantity: line.quantity,
            subtotal: line.subtotal,
          ),
      ];

      final sale = Sale(
        total: current.total,
        itemsCount: items.length,
        discount: current.discount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        paymentMethod: current.paymentMethod,
        customerId: current.selectedCustomer?.id,
        cashierName: cashierName,
        note: current.note.trim(),
        amountTendered: current.amountTendered,
        cardAmount: current.cardAmount,
      );

      final saleId = await _repository.createSale(sale: sale, items: items);

      final created = Sale(
        id: saleId,
        total: sale.total,
        itemsCount: sale.itemsCount,
        discount: sale.discount,
        taxRate: sale.taxRate,
        taxAmount: sale.taxAmount,
        paymentMethod: sale.paymentMethod,
        customerId: sale.customerId,
        cashierName: sale.cashierName,
        note: sale.note,
        amountTendered: sale.amountTendered,
        cardAmount: sale.cardAmount,
        createdAt: sale.createdAt,
      );

      emit(const CartState());
      await _productsCubit.refresh();
      await _customersCubit.refresh();
      await _salesCubit.refresh();
      return created;
    } catch (e) {
      emit(state.copyWith(completing: false));
      rethrow;
    }
  }
}
