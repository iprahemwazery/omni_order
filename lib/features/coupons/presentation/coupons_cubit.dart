import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/coupon.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/coupon_usecases.dart';

class CouponsState {
  final List<Coupon> coupons;
  final bool loading;
  final String? error;

  const CouponsState({
    this.coupons = const [],
    this.loading = false,
    this.error,
  });

  CouponsState copyWith({List<Coupon>? coupons, bool? loading, String? error}) {
    return CouponsState(
      coupons: coupons ?? this.coupons,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  int get activeCount => coupons.where((c) => c.isUsable).length;
}

class CouponsCubit extends Cubit<CouponsState> {
  CouponsCubit(
    this._repository, {
    GetCouponsUseCase? getCoupons,
    CreateCouponUseCase? createCoupon,
    UpdateCouponUseCase? updateCoupon,
    DeleteCouponUseCase? deleteCoupon,
    ValidateCouponUseCase? validateCoupon,
  }) : _getCoupons = getCoupons,
       _createCoupon = createCoupon,
       _updateCoupon = updateCoupon,
       _deleteCoupon = deleteCoupon,
       _validateCoupon = validateCoupon,
       super(const CouponsState());

  final StoreRepository _repository;
  final GetCouponsUseCase? _getCoupons;
  final CreateCouponUseCase? _createCoupon;
  final UpdateCouponUseCase? _updateCoupon;
  final DeleteCouponUseCase? _deleteCoupon;
  final ValidateCouponUseCase? _validateCoupon;

  Future<void> init() async {
    emit(state.copyWith(loading: true));
    try {
      final coupons = await (_getCoupons?.call() ?? _repository.getCoupons());
      emit(CouponsState(coupons: coupons));
    } catch (e) {
      emit(state.copyWith(loading: false, error: 'تعذر تحميل الكوبونات: $e'));
    }
  }

  Future<String?> addCoupon(Coupon coupon) async {
    final code = coupon.code.trim().toUpperCase();
    if (code.isEmpty) return 'اكتب كود الكوبون.';
    final exists = state.coupons.any((c) => c.code.toUpperCase() == code);
    if (exists) return 'الكود "$code" موجود بالفعل.';
    if (_createCoupon != null) {
      await _createCoupon(coupon.copyWith(code: code));
    } else {
      await _repository.addCoupon(coupon);
    }
    await init();
    return null;
  }

  Future<String?> updateCoupon(Coupon coupon) async {
    final code = coupon.code.trim().toUpperCase();
    if (code.isEmpty) return 'اكتب كود الكوبون.';
    final exists = state.coupons.any(
      (c) => c.id != coupon.id && c.code.toUpperCase() == code,
    );
    if (exists) return 'الكود "$code" موجود بالفعل.';
    if (_updateCoupon != null) {
      await _updateCoupon(coupon.copyWith(code: code));
    } else {
      await _repository.updateCoupon(coupon);
    }
    await init();
    return null;
  }

  Future<void> deleteCoupon(int id) async {
    if (_deleteCoupon != null) {
      await _deleteCoupon(id);
    } else {
      await _repository.deleteCoupon(id);
    }
    await init();
  }

  Future<void> toggleActive(Coupon coupon) async {
    if (_updateCoupon != null) {
      await _updateCoupon(coupon.copyWith(isActive: !coupon.isActive));
    } else {
      await _repository.updateCoupon(
        coupon.copyWith(isActive: !coupon.isActive),
      );
    }
    await init();
  }

  Future<Coupon?> validateCoupon(String code, double orderTotal) async {
    if (_validateCoupon != null) {
      return _validateCoupon(code: code, orderTotal: orderTotal);
    }
    final coupon = await _repository.getCouponByCode(code);
    if (coupon == null) return null;
    if (!coupon.isUsable) return null;
    if (orderTotal < coupon.minOrder) return null;
    return coupon;
  }
}
