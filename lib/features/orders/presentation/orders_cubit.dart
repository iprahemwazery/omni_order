import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';
import '../../../domain/models/product.dart';
import '../../../domain/repositories/store_repository.dart';
import '../domain/usecases/orders_usecases.dart';
import '../../products/presentation/products_cubit.dart';

class OrderLine {
  final Product product;
  final double quantity;
  final String notes;

  const OrderLine({
    required this.product,
    required this.quantity,
    this.notes = '',
  });

  double get subtotal => product.price * quantity;

  OrderLine copyWith({Product? product, double? quantity, String? notes}) {
    return OrderLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}

class OrderState {
  final List<OrderLine> lines;
  final double discount;
  final String paymentMethod;
  final int? selectedTableId;
  final int? selectedEmployeeId;
  final int? selectedRiderId;
  final String note;
  final bool isTakeaway;
  final bool completing;
  final double amountTendered;
  final double cardAmount;
  final String orderType;
  final String deliveryAddress;
  final String deliveryPhone;
  final String deliveryNotes;
  final String deliveryPersonName;
  final double deliveryFee;

  const OrderState({
    this.lines = const [],
    this.discount = 0,
    this.paymentMethod = 'نقدي',
    this.selectedTableId,
    this.selectedEmployeeId,
    this.selectedRiderId,
    this.note = '',
    this.isTakeaway = false,
    this.completing = false,
    this.amountTendered = 0,
    this.cardAmount = 0,
    this.orderType = 'hall',
    this.deliveryAddress = '',
    this.deliveryPhone = '',
    this.deliveryNotes = '',
    this.deliveryPersonName = '',
    this.deliveryFee = 0,
  });

  bool get isEmpty => lines.isEmpty;

  double get total {
    final subtotal = lines.fold<double>(0, (sum, l) => sum + l.subtotal);
    return (subtotal - discount + deliveryFee).clamp(0, double.infinity);
  }

  double get totalQuantity =>
      lines.fold<double>(0, (sum, l) => sum + l.quantity);

  int get itemsCount => lines.length;

  OrderState copyWith({
    List<OrderLine>? lines,
    double? discount,
    String? paymentMethod,
    int? selectedTableId,
    int? selectedEmployeeId,
    int? selectedRiderId,
    String? note,
    bool? isTakeaway,
    bool? completing,
    double? amountTendered,
    double? cardAmount,
    String? orderType,
    String? deliveryAddress,
    String? deliveryPhone,
    String? deliveryNotes,
    String? deliveryPersonName,
    double? deliveryFee,
  }) {
    return OrderState(
      lines: lines ?? this.lines,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedTableId: selectedTableId ?? this.selectedTableId,
      selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      note: note ?? this.note,
      isTakeaway: isTakeaway ?? this.isTakeaway,
      completing: completing ?? this.completing,
      amountTendered: amountTendered ?? this.amountTendered,
      cardAmount: cardAmount ?? this.cardAmount,
      orderType: orderType ?? this.orderType,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      deliveryPersonName: deliveryPersonName ?? this.deliveryPersonName,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}

class OrdersCubit extends Cubit<OrderState> {
  OrdersCubit({
    required StoreRepository repository,
    required ProductsCubit productsCubit,
    CreateOrder? createOrder,
  }) : _repository = repository,
       _productsCubit = productsCubit,
       _createOrder = createOrder,
       super(const OrderState());

  final StoreRepository _repository;
  final ProductsCubit _productsCubit;
  final CreateOrder? _createOrder;

  String? addToOrder(Product product, double quantity, {String notes = ''}) {
    if (quantity <= 0) return 'اختر كمية أكبر من صفر.';

    final lines = [...state.lines];
    final index = lines.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      lines[index] = lines[index].copyWith(
        quantity: lines[index].quantity + quantity,
      );
    } else {
      lines.add(OrderLine(product: product, quantity: quantity, notes: notes));
    }
    emit(state.copyWith(lines: lines));
    return null;
  }

  void updateQuantity(int index, double quantity) {
    final lines = [...state.lines];
    if (quantity <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(quantity: quantity);
    }
    emit(state.copyWith(lines: lines));
  }

  void removeFromOrder(int index) {
    final lines = [...state.lines]..removeAt(index);
    emit(state.copyWith(lines: lines));
  }

  void setDiscount(double discount) {
    emit(state.copyWith(discount: discount < 0 ? 0 : discount));
  }

  void setPaymentMethod(String method) {
    emit(state.copyWith(paymentMethod: method));
  }

  void selectTable(int? tableId) {
    emit(
      state.copyWith(
        selectedTableId: tableId,
        orderType: tableId != null ? 'hall' : state.orderType,
        isTakeaway: tableId != null ? false : state.isTakeaway,
      ),
    );
  }

  void selectEmployee(int? employeeId) {
    emit(state.copyWith(selectedEmployeeId: employeeId));
  }

  void selectRider(int? riderId) {
    emit(state.copyWith(selectedRiderId: riderId));
  }

  void setNote(String note) {
    emit(state.copyWith(note: note));
  }

  void setTakeaway(bool isTakeaway) {
    emit(
      state.copyWith(
        isTakeaway: isTakeaway,
        selectedTableId: isTakeaway ? null : state.selectedTableId,
      ),
    );
  }

  void setOrderType(String type) {
    emit(
      state.copyWith(
        orderType: type,
        selectedTableId: type == 'hall' ? state.selectedTableId : null,
      ),
    );
  }

  void setDeliveryAddress(String address) {
    emit(state.copyWith(deliveryAddress: address));
  }

  void setDeliveryPhone(String phone) {
    emit(state.copyWith(deliveryPhone: phone));
  }

  void setDeliveryNotes(String notes) {
    emit(state.copyWith(deliveryNotes: notes));
  }

  void setDeliveryPerson(String name) {
    emit(state.copyWith(deliveryPersonName: name));
  }

  void setDeliveryFee(double fee) {
    emit(state.copyWith(deliveryFee: fee < 0 ? 0 : fee));
  }

  void setAmountTendered(double amount) {
    emit(state.copyWith(amountTendered: amount < 0 ? 0 : amount));
  }

  void setCardAmount(double amount) {
    emit(state.copyWith(cardAmount: amount < 0 ? 0 : amount));
  }

  void clearOrder() => emit(const OrderState());

  Future<int?> _getTableHallId(int tableId) async {
    final table = await _repository.getTable(tableId);
    return table?.hallId;
  }

  Future<RestaurantOrder?> completeOrder({
    String cashierName = '',
    double taxRate = 0,
  }) async {
    final current = state;
    if (current.isEmpty) return null;

    final net = current.total;
    final taxAmount = taxRate <= 0 ? 0.0 : net * taxRate / (100 + taxRate);

    emit(current.copyWith(completing: true));
    try {
      final items = [
        for (final line in current.lines)
          OrderItem(
            orderId: 0,
            productId: line.product.id ?? 0,
            name: line.product.name,
            price: line.product.price,
            quantity: line.quantity,
            subtotal: line.subtotal,
            notes: line.notes,
          ),
      ];

      final order = RestaurantOrder(
        tableId: current.selectedTableId,
        hallId: current.selectedTableId != null
            ? await _getTableHallId(current.selectedTableId!)
            : null,
        employeeId: current.selectedEmployeeId,
        riderId: current.selectedRiderId,
        status: OrderStatus.pending.name,
        orderType: current.orderType,
        total: current.total,
        discount: current.discount,
        taxRate: taxRate,
        taxAmount: taxAmount,
        paymentMethod: current.paymentMethod,
        cashierName: cashierName,
        note: current.note.trim(),
        isTakeaway: current.isTakeaway,
        amountTendered: current.amountTendered,
        cardAmount: current.cardAmount,
        deliveryAddress: current.deliveryAddress,
        deliveryPhone: current.deliveryPhone,
        deliveryNotes: current.deliveryNotes,
        deliveryPersonName: current.deliveryPersonName,
        deliveryFee: current.deliveryFee,
      );

      final orderId =
          await (_createOrder?.call(order: order, items: items) ??
              _repository.createOrder(order: order, items: items));

      final created = RestaurantOrder(
        id: orderId,
        tableId: order.tableId,
        hallId: order.hallId,
        employeeId: order.employeeId,
        riderId: order.riderId,
        status: order.status,
        orderType: order.orderType,
        total: order.total,
        discount: order.discount,
        taxRate: order.taxRate,
        taxAmount: order.taxAmount,
        paymentMethod: order.paymentMethod,
        cashierName: order.cashierName,
        note: order.note,
        isTakeaway: order.isTakeaway,
        amountTendered: order.amountTendered,
        cardAmount: order.cardAmount,
        deliveryAddress: order.deliveryAddress,
        deliveryPhone: order.deliveryPhone,
        deliveryNotes: order.deliveryNotes,
        deliveryPersonName: order.deliveryPersonName,
        deliveryFee: order.deliveryFee,
        createdAt: order.createdAt,
      );

      emit(const OrderState());
      await _productsCubit.refresh();
      return created;
    } catch (e) {
      emit(state.copyWith(completing: false));
      rethrow;
    }
  }
}
