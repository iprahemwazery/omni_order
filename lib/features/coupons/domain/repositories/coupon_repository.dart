import '../../../../domain/models/coupon.dart';

abstract interface class CouponRepository {
  Future<List<Coupon>> getCoupons();

  Future<int> addCoupon(Coupon coupon);

  Future<void> updateCoupon(Coupon coupon);

  Future<void> deleteCoupon(int id);

  Future<Coupon?> getCouponByCode(String code);

  Future<void> useCoupon(int couponId);
}
