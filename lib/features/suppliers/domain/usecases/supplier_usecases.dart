import '../../../../domain/models/purchase.dart';
import '../../../../domain/models/purchase_item.dart';
import '../../../../domain/models/supplier.dart';
import '../../../../domain/models/supplier_payment.dart';
import '../repositories/supplier_repository.dart';

class GetSuppliersUseCase {
  const GetSuppliersUseCase(this._repository);

  final SupplierRepository _repository;

  Future<List<Supplier>> call() => _repository.getSuppliers();
}

class GetSupplierUseCase {
  const GetSupplierUseCase(this._repository);

  final SupplierRepository _repository;

  Future<Supplier?> call(int id) {
    if (id <= 0) return Future.value();
    return _repository.getSupplier(id);
  }
}

class CreateSupplierUseCase {
  const CreateSupplierUseCase(this._repository);

  final SupplierRepository _repository;

  Future<int> call(Supplier supplier) async {
    final normalized = _normalizeSupplier(supplier);
    _validateSupplier(normalized);
    await _ensureUnique(_repository, normalized);
    return _repository.addSupplier(normalized);
  }
}

class UpdateSupplierUseCase {
  const UpdateSupplierUseCase(this._repository);

  final SupplierRepository _repository;

  Future<void> call(Supplier supplier) async {
    if (supplier.id == null || supplier.id! <= 0) {
      throw ArgumentError('معرف المورد مطلوب.');
    }
    final normalized = _normalizeSupplier(supplier);
    _validateSupplier(normalized);
    await _ensureUnique(_repository, normalized);
    return _repository.updateSupplier(normalized);
  }
}

class DeleteSupplierUseCase {
  const DeleteSupplierUseCase(this._repository);

  final SupplierRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError('معرف المورد مطلوب.');
    return _repository.deleteSupplier(id);
  }
}

class GetPurchasesUseCase {
  const GetPurchasesUseCase(this._repository);

  final SupplierRepository _repository;

  Future<List<Purchase>> call({int? limit}) {
    if (limit != null && limit <= 0) {
      throw ArgumentError('الحد الأقصى لعدد الفواتير غير صالح.');
    }
    return _repository.getPurchases(limit: limit);
  }
}

class GetSupplierPurchasesUseCase {
  const GetSupplierPurchasesUseCase(this._repository);

  final SupplierRepository _repository;

  Future<List<Purchase>> call(int supplierId) async {
    if (supplierId <= 0) throw ArgumentError('معرف المورد مطلوب.');
    final purchases = await _repository.getPurchases();
    return purchases
        .where((purchase) => purchase.supplierId == supplierId)
        .toList(growable: false);
  }
}

class GetPurchaseUseCase {
  const GetPurchaseUseCase(this._repository);

  final SupplierRepository _repository;

  Future<Purchase?> call(int id) {
    if (id <= 0) return Future.value();
    return _repository.getPurchase(id);
  }
}

class CreatePurchaseUseCase {
  const CreatePurchaseUseCase(this._repository);

  final SupplierRepository _repository;

  Future<int> call({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('يجب إضافة بند واحد على الأقل للفاتورة.');
    }
    final supplierId = purchase.supplierId;
    if (supplierId == null || supplierId <= 0) {
      throw ArgumentError('معرف المورد مطلوب.');
    }
    final supplier = await _repository.getSupplier(supplierId);
    if (supplier == null) throw StateError('المورد غير موجود.');

    final normalizedItems = <PurchaseItem>[];
    var calculatedTotal = 0.0;
    for (final item in items) {
      _validatePurchaseItem(item);
      final normalized = _normalizePurchaseItem(item);
      calculatedTotal += normalized.subtotal;
      normalizedItems.add(normalized);
    }
    final total = purchase.total > 0 ? purchase.total : calculatedTotal;
    if (total <= 0) throw ArgumentError('إجمالي الفاتورة غير صالح.');
    if (purchase.paidAmount < 0 || purchase.paidAmount > total) {
      throw ArgumentError('المبلغ المدفوع غير صالح.');
    }
    final normalizedPurchase = purchase.copyWith(
      supplierName: supplier.name,
      total: total,
      note: purchase.note.trim(),
    );
    return _repository.createPurchase(
      purchase: normalizedPurchase,
      items: normalizedItems,
    );
  }
}

class SettlePurchaseUseCase {
  const SettlePurchaseUseCase(this._repository);

  final SupplierRepository _repository;

  Future<void> call({required int purchaseId, required double amount}) async {
    if (purchaseId <= 0) throw ArgumentError('معرف الفاتورة مطلوب.');
    if (amount <= 0) {
      throw ArgumentError('مبلغ السداد يجب أن يكون أكبر من صفر.');
    }
    final purchase = await _repository.getPurchase(purchaseId);
    if (purchase == null) throw StateError('فاتورة الشراء غير موجودة.');
    if (amount > purchase.remaining) {
      throw ArgumentError('مبلغ السداد أكبر من المتبقي.');
    }
    return _repository.settlePurchase(purchaseId: purchaseId, amount: amount);
  }
}

class GetPurchaseItemsUseCase {
  const GetPurchaseItemsUseCase(this._repository);

  final SupplierRepository _repository;

  Future<List<PurchaseItem>> call(int purchaseId) {
    if (purchaseId <= 0) return Future.value(const <PurchaseItem>[]);
    return _repository.getPurchaseItems(purchaseId);
  }
}

class GetSupplierPaymentsUseCase {
  const GetSupplierPaymentsUseCase(this._repository);

  final SupplierRepository _repository;

  Future<List<SupplierPayment>> call(int supplierId) {
    if (supplierId <= 0) return Future.value(const <SupplierPayment>[]);
    return _repository.getSupplierPayments(supplierId);
  }
}

Supplier _normalizeSupplier(Supplier supplier) => supplier.copyWith(
  name: supplier.name.trim(),
  phone: supplier.phone.trim(),
  address: supplier.address.trim(),
);

void _validateSupplier(Supplier supplier) {
  if (supplier.name.isEmpty) {
    throw ArgumentError('اسم المورد مطلوب.');
  }
  if (supplier.balance < 0) {
    throw ArgumentError('رصيد المورد لا يمكن أن يكون سالبًا.');
  }
}

Future<void> _ensureUnique(
  SupplierRepository repository,
  Supplier supplier,
) async {
  final suppliers = await repository.getSuppliers();
  final duplicate = suppliers.any(
    (existing) =>
        existing.id != supplier.id &&
        existing.name.trim().toLowerCase() == supplier.name.toLowerCase(),
  );
  if (duplicate) throw StateError('يوجد مورد بالاسم نفسه.');
}

PurchaseItem _normalizePurchaseItem(PurchaseItem item) => item.copyWith(
  name: item.name.trim(),
  unit: item.unit.trim(),
  subtotal: item.quantity * item.price,
);

void _validatePurchaseItem(PurchaseItem item) {
  if (item.name.trim().isEmpty) {
    throw ArgumentError('اسم بند الشراء مطلوب.');
  }
  if (item.quantity <= 0) {
    throw ArgumentError('كمية بند الشراء غير صالحة.');
  }
  if (item.price < 0) {
    throw ArgumentError('سعر بند الشراء غير صالح.');
  }
  if (item.conversionFactor <= 0) {
    throw ArgumentError('معامل التحويل يجب أن يكون أكبر من صفر.');
  }
}
