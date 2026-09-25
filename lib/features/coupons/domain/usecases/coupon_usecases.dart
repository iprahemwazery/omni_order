import '../../../../domain/models/coupon.dart';
import '../repositories/coupon_repository.dart';

class GetCouponsUseCase {
  const GetCouponsUseCase(this._repository);

  final CouponRepository _repository;

  Future<List<Coupon>> call() => _repository.getCoupons();
}

class GetCouponByCodeUseCase {
  const GetCouponByCodeUseCase(this._repository);

  final CouponRepository _repository;

  Future<Coupon?> call(String code) {
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return Future.value();
    return _repository.getCouponByCode(normalized);
  }
}

class CreateCouponUseCase {
  const CreateCouponUseCase(this._repository);

  final CouponRepository _repository;

  Future<int> call(Coupon coupon) async {
    final normalized = _normalizeCoupon(coupon);
    _validateCoupon(normalized);
    final existing = await _repository.getCouponByCode(normalized.code);
    if (existing != null) {
      throw StateError('كود الكوبون مستخدم بالفعل.');
    }
    return _repository.addCoupon(normalized);
  }
}

class UpdateCouponUseCase {
  const UpdateCouponUseCase(this._repository);

  final CouponRepository _repository;

  Future<void> call(Coupon coupon) async {
    if (coupon.id == null || coupon.id! <= 0) {
      throw ArgumentError('معرف الكوبون مطلوب.');
    }
    final normalized = _normalizeCoupon(coupon);
    _validateCoupon(normalized);
    final existing = await _repository.getCouponByCode(normalized.code);
    if (existing != null && existing.id != coupon.id) {
      throw StateError('كود الكوبون مستخدم بالفعل.');
    }
    return _repository.updateCoupon(normalized);
  }
}

class DeleteCouponUseCase {
  const DeleteCouponUseCase(this._repository);

  final CouponRepository _repository;

  Future<void> call(int id) {
    if (id <= 0) throw ArgumentError('معرف الكوبون مطلوب.');
    return _repository.deleteCoupon(id);
  }
}

class ValidateCouponUseCase {
  const ValidateCouponUseCase(this._repository);

  final CouponRepository _repository;

  Future<Coupon?> call({
    required String code,
    required double orderTotal,
  }) async {
    if (orderTotal < 0) return null;
    final normalized = _normalizeCode(code);
    if (normalized.isEmpty) return null;
    final coupon = await _repository.getCouponByCode(normalized);
    if (coupon == null || !coupon.isUsable) return null;
    if (orderTotal < coupon.minOrder) return null;
    return coupon;
  }
}

class CouponApplication {
  const CouponApplication({
    required this.coupon,
    required this.discount,
    required this.total,
  });

  final Coupon coupon;
  final double discount;
  final double total;
}

class ApplyCouponUseCase {
  const ApplyCouponUseCase(this._repository);

  final CouponRepository _repository;

  Future<CouponApplication?> call({
    required String code,
    required double orderTotal,
  }) async {
    final coupon = await ValidateCouponUseCase(_repository)(
      code: code,
      orderTotal: orderTotal,
    );
    if (coupon == null) return null;
    final discount = coupon.calculateDiscount(orderTotal);
    return CouponApplication(
      coupon: coupon,
      discount: discount,
      total: orderTotal - discount,
    );
  }
}

class RedeemCouponUseCase {
  const RedeemCouponUseCase(this._repository);

  final CouponRepository _repository;

  Future<Coupon?> call({
    required String code,
    required double orderTotal,
  }) async {
    final application = await ApplyCouponUseCase(_repository)(
      code: code,
      orderTotal: orderTotal,
    );
    final coupon = application?.coupon;
    if (application == null || coupon?.id == null) return null;
    await _repository.useCoupon(coupon!.id!);
    return coupon.copyWith(usedCount: coupon.usedCount + 1);
  }
}

String _normalizeCode(String code) => code.trim().toUpperCase();

Coupon _normalizeCoupon(Coupon coupon) => coupon.copyWith(
  code: _normalizeCode(coupon.code),
  description: coupon.description.trim(),
);

void _validateCoupon(Coupon coupon) {
  if (coupon.code.isEmpty) {
    throw ArgumentError('كود الكوبون مطلوب.');
  }
  if (coupon.discountValue <= 0) {
    throw ArgumentError('قيمة الخصم يجب أن تكون أكبر من صفر.');
  }
  if (coupon.discountType == CouponType.percent && coupon.discountValue > 100) {
    throw ArgumentError('نسبة الخصم لا يمكن أن تتجاوز مئة بالمئة.');
  }
  if (coupon.minOrder < 0 || coupon.maxUses < 0) {
    throw ArgumentError('قيم الحد الأدنى وعدد الاستخدامات غير صالحة.');
  }
}
