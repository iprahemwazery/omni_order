import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/supplier.dart';
import '../../../domain/models/purchase.dart';
import '../../../domain/models/purchase_item.dart';
import '../../../domain/models/supplier_payment.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/supplier_usecases.dart';

class SuppliersState {
  final List<Supplier> suppliers;
  final List<Purchase> purchases;
  final bool loading;
  final String? error;

  const SuppliersState({
    this.suppliers = const [],
    this.purchases = const [],
    this.loading = false,
    this.error,
  });

  SuppliersState copyWith({
    List<Supplier>? suppliers,
    List<Purchase>? purchases,
    bool? loading,
    String? error,
  }) {
    return SuppliersState(
      suppliers: suppliers ?? this.suppliers,
      purchases: purchases ?? this.purchases,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  double get totalPending {
    return purchases
        .where((p) => !p.isFullyPaid)
        .fold<double>(0, (s, p) => s + p.remaining);
  }
}

class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit(
    this._repository, {
    GetSuppliersUseCase? getSuppliers,
    CreateSupplierUseCase? createSupplier,
    UpdateSupplierUseCase? updateSupplier,
    DeleteSupplierUseCase? deleteSupplier,
    GetPurchasesUseCase? getPurchases,
    CreatePurchaseUseCase? createPurchase,
    SettlePurchaseUseCase? settlePurchase,
    GetPurchaseItemsUseCase? getPurchaseItems,
    GetSupplierPaymentsUseCase? getSupplierPayments,
  }) : _getSuppliers = getSuppliers,
       _createSupplier = createSupplier,
       _updateSupplier = updateSupplier,
       _deleteSupplier = deleteSupplier,
       _getPurchases = getPurchases,
       _createPurchase = createPurchase,
       _settlePurchase = settlePurchase,
       _getPurchaseItems = getPurchaseItems,
       _getSupplierPayments = getSupplierPayments,
       super(const SuppliersState());

  final StoreRepository _repository;
  final GetSuppliersUseCase? _getSuppliers;
  final CreateSupplierUseCase? _createSupplier;
  final UpdateSupplierUseCase? _updateSupplier;
  final DeleteSupplierUseCase? _deleteSupplier;
  final GetPurchasesUseCase? _getPurchases;
  final CreatePurchaseUseCase? _createPurchase;
  final SettlePurchaseUseCase? _settlePurchase;
  final GetPurchaseItemsUseCase? _getPurchaseItems;
  final GetSupplierPaymentsUseCase? _getSupplierPayments;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final suppliers =
          await (_getSuppliers?.call() ?? _repository.getSuppliers());
      final purchases =
          await (_getPurchases?.call() ?? _repository.getPurchases());
      emit(SuppliersState(suppliers: suppliers, purchases: purchases));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'تعذر تحميل البيانات: $e'));
    }
  }

  Future<String?> addSupplier(Supplier supplier) async {
    final trimmed = supplier.name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم المورد.';
    final exists = state.suppliers.any((s) => s.name.trim() == trimmed);
    if (exists) return 'المورد "$trimmed" موجود بالفعل.';
    if (_createSupplier != null) {
      await _createSupplier(supplier);
    } else {
      await _repository.addSupplier(supplier);
    }
    await init();
    return null;
  }

  Future<String?> updateSupplier(Supplier supplier) async {
    final trimmed = supplier.name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم المورد.';
    final exists = state.suppliers.any(
      (s) => s.id != supplier.id && s.name.trim() == trimmed,
    );
    if (exists) return 'المورد "$trimmed" موجود بالفعل.';
    if (_updateSupplier != null) {
      await _updateSupplier(supplier);
    } else {
      await _repository.updateSupplier(supplier);
    }
    await init();
    return null;
  }

  Future<void> deleteSupplier(int id) async {
    if (_deleteSupplier != null) {
      await _deleteSupplier(id);
    } else {
      await _repository.deleteSupplier(id);
    }
    await init();
  }

  Future<int> createPurchase({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    final id = _createPurchase != null
        ? await _createPurchase(purchase: purchase, items: items)
        : await _repository.createPurchase(purchase: purchase, items: items);
    await init();
    return id;
  }

  Future<void> settlePurchase(int purchaseId, double amount) async {
    if (_settlePurchase != null) {
      await _settlePurchase(purchaseId: purchaseId, amount: amount);
    } else {
      await _repository.settlePurchase(purchaseId: purchaseId, amount: amount);
    }
    await init();
  }

  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) async {
    return await (_getPurchaseItems?.call(purchaseId) ??
        _repository.getPurchaseItems(purchaseId));
  }

  Future<List<SupplierPayment>> getSupplierPayments(int supplierId) async {
    return await (_getSupplierPayments?.call(supplierId) ??
        _repository.getSupplierPayments(supplierId));
  }
}
