import '../../../../domain/models/purchase.dart';
import '../../../../domain/models/purchase_item.dart';
import '../../../../domain/models/supplier.dart';
import '../../../../domain/models/supplier_payment.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  const SupplierRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Supplier>> getSuppliers() => _storeRepository.getSuppliers();

  @override
  Future<int> addSupplier(Supplier supplier) =>
      _storeRepository.addSupplier(supplier);

  @override
  Future<void> updateSupplier(Supplier supplier) =>
      _storeRepository.updateSupplier(supplier);

  @override
  Future<void> deleteSupplier(int id) => _storeRepository.deleteSupplier(id);

  @override
  Future<Supplier?> getSupplier(int id) => _storeRepository.getSupplier(id);

  @override
  Future<List<Purchase>> getPurchases({int? limit}) =>
      _storeRepository.getPurchases(limit: limit);

  @override
  Future<Purchase?> getPurchase(int id) => _storeRepository.getPurchase(id);

  @override
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) =>
      _storeRepository.getPurchaseItems(purchaseId);

  @override
  Future<int> createPurchase({
    required Purchase purchase,
    required List<PurchaseItem> items,
  }) => _storeRepository.createPurchase(purchase: purchase, items: items);

  @override
  Future<void> settlePurchase({
    required int purchaseId,
    required double amount,
  }) => _storeRepository.settlePurchase(purchaseId: purchaseId, amount: amount);

  @override
  Future<List<SupplierPayment>> getSupplierPayments(int supplierId) =>
      _storeRepository.getSupplierPayments(supplierId);
}
