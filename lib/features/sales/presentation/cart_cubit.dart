import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/cart_line.dart';
import '../../../../domain/models/customer.dart';
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
    if (kPaymentMethods.contains(method)) {
      emit(state.copyWith(paymentMethod: method));
    }
  }

  void selectCustomer(Customer? customer) {
    emit(state.copyWith(selectedCustomer: customer));
  }

  void setSaleNote(String note) {
    emit(state.copyWith(note: note));
  }

  void clearCart() => emit(const CartState());

  /// يُنهي البيع: يحفظ الفاتورة، يخصم المخزون (داخل معاملة)، يحدّث مديونية
  /// العميل، ويرجّع الفاتورة المنشأة. [cashierName] هو اسم المستخدم المسجل.
  Future<Sale?> completeSale({String cashierName = ''}) async {
    final current = state;
    if (current.isEmpty) return null;

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
        paymentMethod: current.paymentMethod,
        customerId: current.selectedCustomer?.id,
        cashierName: cashierName,
        note: current.note.trim(),
      );

      final saleId = await _repository.createSale(sale: sale, items: items);

      // تحديث مديونية العميل عند البيع "آجل".
      if (current.paymentMethod == 'آجل' && current.selectedCustomer != null) {
        final customer = current.selectedCustomer!;
        await _repository.updateCustomer(
          customer.copyWith(balance: customer.balance + current.total),
        );
      }

      final created = Sale(
        id: saleId,
        total: sale.total,
        itemsCount: sale.itemsCount,
        discount: sale.discount,
        paymentMethod: sale.paymentMethod,
        customerId: sale.customerId,
        cashierName: sale.cashierName,
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
