import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/supplier.dart';
import '../../../../domain/models/supplier_payment.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'suppliers_state.dart';

/// يدير قائمة الموردين والمديونيات وسجل السداد للموردين.
class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit(this._repository) : super(const SuppliersState(loading: true));

  final StoreRepository _repository;

  Future<void> init() async {
    emit(const SuppliersState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final suppliers = await _repository.getSuppliers();
      emit(SuppliersState(suppliers: suppliers));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل الموردين', e)));
    }
  }

  Future<String?> addSupplier(
    String name, {
    String phone = '',
    String address = '',
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'اكتب اسم المورد.';
    final phoneTrimmed = phone.trim();
    final addressTrimmed = address.trim();
    final id = await _repository.addSupplier(
      Supplier(name: trimmed, phone: phoneTrimmed, address: addressTrimmed),
    );
    emit(
      state.copyWith(
        suppliers: [
          ...state.suppliers,
          Supplier(
            id: id,
            name: trimmed,
            phone: phoneTrimmed,
            address: addressTrimmed,
          ),
        ],
      ),
    );
    return null;
  }

  Future<void> updateSupplier(Supplier supplier) async {
    await _repository.updateSupplier(supplier);
    emit(
      state.copyWith(
        suppliers: [
          for (final s in state.suppliers) s.id == supplier.id ? supplier : s,
        ],
      ),
    );
  }

  Future<void> deleteSupplier(Supplier supplier) async {
    if (supplier.id == null) return;
    await _repository.deleteSupplier(supplier.id!);
    emit(
      state.copyWith(
        suppliers: state.suppliers.where((s) => s.id != supplier.id).toList(),
      ),
    );
  }

  Future<String?> recordSupplierPayment(
    Supplier supplier,
    double amount, {
    int? purchaseId,
  }) async {
    if (amount <= 0) return 'أدخل مبلغًا أكبر من صفر.';
    if (supplier.id == null) return 'مورد غير صالح.';
    if (amount > supplier.balance) return 'المبلغ أكبر من المديونية.';
    try {
      await _repository.addSupplierPayment(
        SupplierPayment(
          supplierId: supplier.id!,
          amount: amount,
          purchaseId: purchaseId,
        ),
      );
      await refresh();
      return null;
    } catch (e) {
      return safeErrorMessage('تعذر تسجيل السداد', e);
    }
  }

  Future<List<SupplierPayment>> paymentsOf(Supplier supplier) async {
    if (supplier.id == null) return const [];
    return _repository.getSupplierPayments(supplier.id!);
  }
}
