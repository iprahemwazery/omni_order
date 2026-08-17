import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../domain/models/customer.dart';
import '../../../../domain/models/customer_payment.dart';
import '../../../../domain/repositories/store_repository.dart';
import 'customers_state.dart';

/// يدير قائمة العملاء والمديونيات وتسجيل السداد.
class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit(this._repository)
      : super(const CustomersState(loading: true));

  final StoreRepository _repository;

  Future<void> init() async {
    emit(const CustomersState(loading: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final customers = await _repository.getCustomers();
      emit(CustomersState(customers: customers));
    } catch (e) {
      emit(state.copyWith(error: safeErrorMessage('تعذر تحميل العملاء', e)));
    }
  }

  /// يضيف عميلًا ويعيد (العميل الجديد مع رقمه، أو رسالة خطأ).
  Future<(Customer?, String?)> addCustomer(String name,
      {String phone = ''}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return (null, 'اكتب اسم العميل.');
    try {
      final phoneTrimmed = phone.trim();
      final id = await _repository.addCustomer(
        Customer(name: trimmed, phone: phoneTrimmed),
      );
      final created = Customer(id: id, name: trimmed, phone: phoneTrimmed);
      emit(state.copyWith(customers: [...state.customers, created]));
      return (created, null);
    } catch (e) {
      return (null, safeErrorMessage('تعذر إضافة العميل', e));
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    await _repository.updateCustomer(customer);
    emit(state.copyWith(
      customers: [
        for (final c in state.customers) c.id == customer.id ? customer : c,
      ],
    ));
  }

  Future<void> deleteCustomer(Customer customer) async {
    if (customer.id == null) return;
    await _repository.deleteCustomer(customer.id!);
    emit(state.copyWith(
      customers: state.customers.where((c) => c.id != customer.id).toList(),
    ));
  }

  /// تسجيل سداد جزء من مديونية عميل مع حفظه في سجل الحركة.
  Future<String?> recordCustomerPayment(Customer customer, double amount) async {
    if (amount <= 0) return 'أدخل مبلغًا أكبر من صفر.';
    if (customer.id == null) return 'عميل غير صالح.';
    if (amount > customer.balance) return 'المبلغ أكبر من المديونية.';
    try {
      await _repository.addCustomerPayment(
        CustomerPayment(customerId: customer.id!, amount: amount),
      );
      await refresh();
      return null;
    } catch (e) {
      return safeErrorMessage('تعذر تسجيل السداد', e);
    }
  }

  /// سجل دفعات هذا العميل (الأحدث أولًا).
  Future<List<CustomerPayment>> paymentsOf(Customer customer) async {
    if (customer.id == null) return const [];
    return _repository.getCustomerPayments(customer.id!);
  }
}
