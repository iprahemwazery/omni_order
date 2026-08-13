import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/product.dart';
import '../../../../domain/models/purchase.dart';
import '../../../../domain/models/purchase_item.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../products/presentation/products_cubit.dart';
import 'purchases_state.dart';

/// سطر إدخال في فاتورة شراء (صنف + كمية + سعر شراء).
typedef PurchaseLine = ({Product product, double quantity, double price});

/// يدير سجل المشتريات وإنشاء فواتير الشراء.
class PurchasesCubit extends Cubit<PurchasesState> {
  PurchasesCubit(this._repository, this._productsCubit)
    : super(const PurchasesState(loading: true));

  final StoreRepository _repository;
  final ProductsCubit _productsCubit;

  Future<void> init() async {
    emit(const PurchasesState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final purchases = await _repository.getPurchases();
      emit(PurchasesState(purchases: purchases));
    } catch (e) {
      emit(state.copyWith(error: 'تعذر تحميل المشتريات: $e'));
    }
  }

  /// ينشئ فاتورة شراء: يزيد المخزون ويحدّث سعر التكلفة لأصنافها.
  Future<String?> createPurchase({
    required String supplierName,
    int? supplierId,
    required String note,
    required List<PurchaseLine> lines,
    double paidAmount = 0,
  }) async {
    if (lines.isEmpty) return 'أضف صنفًا واحدًا على الأقل.';
    for (final line in lines) {
      if (line.quantity <= 0)
        return 'كمية "${line.product.name}" يجب أن تكون أكبر من صفر.';
      if (line.price < 0) return 'سعر "${line.product.name}" غير صحيح.';
    }

    final total = lines.fold(0.0, (sum, l) => sum + l.quantity * l.price);
    if (paidAmount < 0) return 'المبلغ المدفوع لا يمكن أن يكون سالبًا.';
    if (paidAmount > total)
      return 'المبلغ المدفوع لا يمكن أن يكون أكبر من إجمالي الفاتورة.';

    final items = [
      for (final line in lines)
        PurchaseItem(
          purchaseId: 0,
          productId: line.product.id ?? 0,
          name: line.product.name,
          quantity: line.quantity,
          price: line.price,
          subtotal: line.quantity * line.price,
        ),
    ];

    await _repository.createPurchase(
      purchase: Purchase(
        supplierId: supplierId,
        supplierName: supplierName,
        total: total,
        paidAmount: paidAmount,
        note: note,
      ),
      items: items,
    );
    await refresh();
    await _productsCubit.refresh();
    return null;
  }

  /// بنود فاتورة شراء معيّنة (تُحمَّل عند عرض التفاصيل).
  Future<List<PurchaseItem>> purchaseItemsOf(int purchaseId) =>
      _repository.getPurchaseItems(purchaseId);
}
