import '../../../../domain/models/purchase.dart';
import '../../../../domain/models/purchase_item.dart';
import '../../../../domain/models/supplier.dart';
import '../../../../domain/models/supplier_payment.dart';

abstract interface class SupplierRepository {
  Future<List<Supplier>> getSuppliers();

  Future<int> addSupplier(Supplier supplier);

  Future<void> updateSupplier(Supplier supplier);

  Future<void> deleteSupplier(int id);

  Future<Supplier?> getSupplier(int id);

  Future<List<Purchase>> getPurchases({int? limit});

  Future<Purchase?> getPurchase(int id);

  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId);

  Future<int> createPurchase({
    required Purchase purchase,
    required List<PurchaseItem> items,
  });

  Future<void> settlePurchase({
    required int purchaseId,
    required double amount,
  });

  Future<List<SupplierPayment>> getSupplierPayments(int supplierId);
}
