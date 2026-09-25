import '../../../../domain/models/coupon.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../../domain/repositories/coupon_repository.dart';

class CouponRepositoryImpl implements CouponRepository {
  const CouponRepositoryImpl(this._storeRepository);

  final StoreRepository _storeRepository;

  @override
  Future<List<Coupon>> getCoupons() => _storeRepository.getCoupons();

  @override
  Future<int> addCoupon(Coupon coupon) => _storeRepository.addCoupon(coupon);

  @override
  Future<void> updateCoupon(Coupon coupon) =>
      _storeRepository.updateCoupon(coupon);

  @override
  Future<void> deleteCoupon(int id) => _storeRepository.deleteCoupon(id);

  @override
  Future<Coupon?> getCouponByCode(String code) =>
      _storeRepository.getCouponByCode(code);

  @override
  Future<void> useCoupon(int couponId) => _storeRepository.useCoupon(couponId);
}
