import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/models/employee.dart';
import '../../../../domain/models/restaurant_table.dart';
import '../../../../domain/models/sale.dart';
import '../../../auth/presentation/auth_cubit.dart';
import '../../../settings/presentation/settings_cubit.dart';
import '../../../../domain/repositories/store_repository.dart';
import '../cart_cubit.dart';
import '../cart_state.dart';

Future<Sale?> showCheckoutSheet(BuildContext context) {
  return showModalBottomSheet<Sale>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CheckoutSheet(),
  );
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet();

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

enum _CheckoutStep { orderType, normalPayment, selectTable, selectDelivery, splitBill }

enum _DiscountType { none, percent, amount }

enum SplitBillMode { equal, byItem, custom }

class _CheckoutSheetState extends State<_CheckoutSheet> {
  _CheckoutStep _step = _CheckoutStep.orderType;
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tenderedController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();
  _DiscountType _discountType = _DiscountType.none;
  String _paymentMethod = PaymentMethod.all.first;
  String? _error;
  bool _saving = false;

  List<RestaurantTable> _tables = [];
  List<Employee> _deliveryPersons = [];
  Set<String> _occupiedTableNames = {};
  Set<String> _occupiedDeliveryNames = {};
  bool _loadingLists = false;

  // ── Split Bill state ──
  SplitBillMode _splitMode = SplitBillMode.equal;
  int _splitCount = 2;
  final List<double> _splitAmounts = [];
  final List<Set<int>> _splitItemIndices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _noteController.dispose();
    _tenderedController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loadingLists = true);
    try {
      final repo = context.read<StoreRepository>();
      final results = await Future.wait([
        repo.getTables(),
        repo.getDeliveryPersons(),
        repo.getDeferredSales(),
      ]);
      final tables = results[0] as List<RestaurantTable>;
      final deliveryPersons = results[1] as List<Employee>;
      final deferredSales = results[2] as List<Sale>;

      final occupiedTables = <String>{};
      final occupiedDelivery = <String>{};
      for (final sale in deferredSales) {
        if (sale.tableName.isNotEmpty) occupiedTables.add(sale.tableName);
        if (sale.customerName.isNotEmpty) {
          occupiedDelivery.add(sale.customerName);
        }
      }

      if (mounted) {
        setState(() {
          _tables = tables;
          _deliveryPersons = deliveryPersons;
          _occupiedTableNames = occupiedTables;
          _occupiedDeliveryNames = occupiedDelivery;
          _loadingLists = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLists = false);
    }
  }

  double get _discount {
    final subtotal = context.read<CartCubit>().state.subtotal;
    final value = double.tryParse(_discountController.text);
    if (value == null || value <= 0) return 0;
    switch (_discountType) {
      case _DiscountType.percent:
        return (subtotal * value / 100).clamp(0, subtotal);
      case _DiscountType.amount:
        return value.clamp(0, subtotal);
      case _DiscountType.none:
        return 0;
    }
  }

  double get _net {
    final cart = context.read<CartCubit>().state;
    return cart.subtotal - _discount;
  }

  double get _tip {
    return double.tryParse(_tipController.text) ?? 0;
  }

  double? get _tenderedInput {
    final value = double.tryParse(_tenderedController.text);
    return (value == null || value <= 0) ? null : value;
  }

  void _onOrderTypeSelected(String type) {
    context.read<CartCubit>().setOrderType(type);
    if (type == 'عميل_عادي') {
      setState(() => _step = _CheckoutStep.normalPayment);
    } else if (type == 'صاله') {
      setState(() => _step = _CheckoutStep.selectTable);
    } else if (type == 'دلفري') {
      setState(() => _step = _CheckoutStep.selectDelivery);
    }
  }

  void _onTableTap(String tableName) {
    if (_occupiedTableNames.contains(tableName)) {
      setState(() => _error = 'التريبية "$tableName" عليها فاتورة آجلة لم تُسدّد.');
      return;
    }
    context.read<CartCubit>().setTableName(tableName);
    _completeAsDeferred();
  }

  void _onDeliveryTap(String personName) {
    if (_occupiedDeliveryNames.contains(personName)) {
      setState(() => _error = 'الدليفري "$personName" عليه فاتورة آجلة لم تُسدّد.');
      return;
    }
    context.read<CartCubit>().setCustomerName(personName);
    _completeAsDeferred();
  }

  Future<void> _completeAsDeferred() async {
    final cart = context.read<CartCubit>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      cart.setPaymentMethod(PaymentMethod.deferred);
      cart.setSaleNote(_noteController.text);
      cart.setAmountTendered(0);
      cart.setCardAmount(0);
      cart.setCartDiscount(_discount);
      final cashierName =
          context.read<AuthCubit>().state.admin?.username ?? '';
      final taxRate = context.read<SettingsCubit>().state.settings.taxRate;
      final sale =
          await cart.completeSale(cashierName: cashierName, taxRate: taxRate);
      if (!mounted) return;
      Navigator.of(context).pop(sale);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = safeErrorMessage('حدث خطأ أثناء حفظ الفاتورة', e);
        });
      }
    }
  }

  Future<void> _confirm() async {
    final cart = context.read<CartCubit>();
    final net = _net;

    double tendered;
    double cardAmount;
    if (_paymentMethod == PaymentMethod.deferred) {
      tendered = 0;
      cardAmount = 0;
    } else if (_paymentMethod == PaymentMethod.mixed) {
      final cashPortion = _tenderedInput;
      if (cashPortion == null || cashPortion <= 0) {
        setState(() => _error = 'أدخل الجزء المدفوع نقدًا.');
        return;
      }
      if (cashPortion >= net) {
        setState(
          () => _error = 'الجزء نقدًا يجب أن يقل عن الصافي ليبقى جزء للشبكة.',
        );
        return;
      }
      tendered = net;
      cardAmount = net - cashPortion;
    } else {
      final entered = _tenderedInput;
      if (entered != null && entered < net) {
        setState(
          () => _error = 'المبلغ المدفوع ($entered) أقل من الصافي ($net).',
        );
        return;
      }
      tendered = entered ?? net;
      cardAmount = 0;
    }

    setState(() => _saving = true);
    try {
      cart.setCartDiscount(_discount);
      cart.setPaymentMethod(_paymentMethod);
      cart.setSaleNote(_noteController.text);
      cart.setAmountTendered(tendered);
      cart.setCardAmount(cardAmount);
      cart.setTip(_tip);
      final cashierName =
          context.read<AuthCubit>().state.admin?.username ?? '';
      final taxRate = context.read<SettingsCubit>().state.settings.taxRate;
      final sale =
          await cart.completeSale(cashierName: cashierName, taxRate: taxRate);
      if (!mounted) return;
      Navigator.of(context).pop(sale);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = safeErrorMessage('حدث خطأ أثناء حفظ الفاتورة', e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit>().state;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _CheckoutStep.orderType) ...[
              _buildOrderTypeStep(cart),
            ] else if (_step == _CheckoutStep.normalPayment) ...[
              _buildNormalPaymentStep(cart),
            ] else if (_step == _CheckoutStep.selectTable) ...[
              _buildTableStep(cart),
            ] else if (_step == _CheckoutStep.selectDelivery) ...[
              _buildDeliveryStep(cart),
            ] else if (_step == _CheckoutStep.splitBill) ...[
              _buildSplitBillStep(cart),
            ],
          ],
        ),
      ),
    );
  }

  // ── الخطوة 1: اختيار نوع البيع ──────────────────────────

  Widget _buildOrderTypeStep(CartState cart) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            'نوع البيع',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'اختر نوع العميل',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _orderTypeCard(
          icon: Icons.person_outline,
          title: 'عميل عادي',
          subtitle: 'فاتورة مباشرة بالدفع',
          color: AppColors.primary,
          onTap: () => _onOrderTypeSelected('عميل_عادي'),
        ),
        const SizedBox(height: 12),
        _orderTypeCard(
          icon: Icons.restaurant_outlined,
          title: 'صاله',
          subtitle: 'فاتورة آجلة — يُدفع عند المغادرة',
          color: AppColors.primary,
          onTap: () => _onOrderTypeSelected('صاله'),
        ),
        const SizedBox(height: 12),
        _orderTypeCard(
          icon: Icons.delivery_dining_outlined,
          title: 'دلفري',
          subtitle: 'فاتورة آجلة — يُدفع عند التوصيل',
          color: AppColors.warning,
          onTap: () => _onOrderTypeSelected('دلفري'),
        ),
        const SizedBox(height: 12),
        _orderTypeCard(
          icon: Icons.call_split_outlined,
          title: 'تقسيم الفاتورة',
          subtitle: 'تقسيم على عدة أشخاص',
          color: AppColors.info,
          onTap: () => setState(() {
            _step = _CheckoutStep.splitBill;
            _initSplitBill();
          }),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  Widget _orderTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── الخطوة 2 أ: الدفع الطبيعي (عميل عادي) ─────────────

  Widget _buildNormalPaymentStep(CartState cart) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          title: 'إتمام البيع',
          onBack: () => setState(() => _step = _CheckoutStep.orderType),
        ),
        const SizedBox(height: 20),
        _label('طريقة الدفع'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final method in PaymentMethod.all)
              ChoiceChip(
                label: Text(method),
                selected: _paymentMethod == method,
                onSelected: (_) => setState(() {
                  _paymentMethod = method;
                  _tenderedController.clear();
                }),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _paymentMethod == method
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (_paymentMethod == PaymentMethod.mixed) ...[
          const SizedBox(height: 14),
          _label('الجزء المدفوع نقدًا'),
          const SizedBox(height: 8),
          TextField(
            controller: _tenderedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
              hintText: 'مثال: 30',
              helperText: 'الجزء المتبقي يُدفع بالشبكة',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ] else if (PaymentMethod.paidNow.contains(_paymentMethod)) ...[
          const SizedBox(height: 14),
          _label('المبلغ المدفوع (اختياري)'),
          const SizedBox(height: 8),
          TextField(
            controller: _tenderedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.payments_outlined),
              hintText: 'مثال: 100',
              helperText: 'اتركه فارغًا إذا دفع الصافي كاملًا',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 18),
        _label('خصم'),
        const SizedBox(height: 8),
        Row(
          children: [
            ChoiceChip(
              label: const Text('بدون'),
              selected: _discountType == _DiscountType.none,
              onSelected: (_) => setState(() {
                _discountType = _DiscountType.none;
                _discountController.clear();
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('نسبة %'),
              selected: _discountType == _DiscountType.percent,
              onSelected: (_) =>
                  setState(() => _discountType = _DiscountType.percent),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('مبلغ'),
              selected: _discountType == _DiscountType.amount,
              onSelected: (_) =>
                  setState(() => _discountType = _DiscountType.amount),
            ),
          ],
        ),
        if (_discountType != _DiscountType.none) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _discountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.local_offer_outlined),
              hintText: _discountType == _DiscountType.percent
                  ? 'مثال: 10'
                  : 'مثال: 50',
              suffixText:
                  _discountType == _DiscountType.percent ? '%' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 16),
        _label('بقشيش (اختياري)'),
        const SizedBox(height: 8),
        TextField(
          controller: _tipController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.volunteer_activism_outlined),
            hintText: 'مثال: 10',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _label('ملاحظة على الفاتورة (اختياري)'),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.notes_outlined),
            hintText: 'مثال: ملاحظة إضافية',
          ),
        ),
        const SizedBox(height: 16),
        _totals(cart),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _confirm,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_saving ? 'جارٍ الحفظ...' : 'تأكيد البيع'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  // ── الخطوة 2 ب: اختيار التريبية (صاله) ──────────────────

  Widget _buildTableStep(CartState cart) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          title: 'اختيار التريبية',
          onBack: () => setState(() => _step = _CheckoutStep.orderType),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'فاتورة آجلة — يُدفع عند مغادرة الصاله',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loadingLists)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_tables.isEmpty)
          _emptyListMessage('لا توجد ترابيزات مسجلة')
        else
          _buildTablesGrid(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  Widget _buildTablesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tables.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final table = _tables[index];
        final tableName = '${table.number}';
        final isOccupied = _occupiedTableNames.contains(tableName);
        return _tableOrPersonCard(
          label: tableName,
          icon: Icons.table_restaurant_outlined,
          isOccupied: isOccupied,
          color: AppColors.primary,
          onTap: isOccupied ? null : () => _onTableTap(tableName),
        );
      },
    );
  }

  // ── الخطوة 2 ج: الدلفري ────────────────────────────────

  Widget _buildDeliveryStep(CartState cart) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          title: 'اختيار الدلفري',
          onBack: () => setState(() => _step = _CheckoutStep.orderType),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'فاتورة آجلة — يُدفع عند التوصيل',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loadingLists)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_deliveryPersons.isEmpty)
          _emptyListMessage('لا يوجد دليفري مسجل')
        else
          _buildDeliveryGrid(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  Widget _buildDeliveryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _deliveryPersons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final person = _deliveryPersons[index];
        final isOccupied = _occupiedDeliveryNames.contains(person.name);
        return _tableOrPersonCard(
          label: person.name,
          icon: Icons.delivery_dining_outlined,
          isOccupied: isOccupied,
          color: AppColors.warning,
          onTap: isOccupied ? null : () => _onDeliveryTap(person.name),
        );
      },
    );
  }

  // ── الخطوة 3: تقسيم الفاتورة ──────────────────────────────

  void _initSplitBill() {
    final cart = context.read<CartCubit>().state;
    final net = cart.subtotal - _discount;
    final tip = _tip;
    final total = net + tip;
    _splitAmounts.clear();
    _splitItemIndices.clear();
    for (int i = 0; i < _splitCount; i++) {
      _splitAmounts.add(total / _splitCount);
      _splitItemIndices.add({});
    }
  }

  Widget _buildSplitBillStep(CartState cart) {
    final discount = _discount;
    final net = cart.subtotal - discount;
    final tip = _tip;
    final total = net + tip;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          title: 'تقسيم الفاتورة',
          onBack: () => setState(() => _step = _CheckoutStep.orderType),
        ),
        const SizedBox(height: 12),
        _label('طريقة التقسيم'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('تقسيم متساوي'),
              selected: _splitMode == SplitBillMode.equal,
              onSelected: (_) => setState(() {
                _splitMode = SplitBillMode.equal;
                _initSplitBill();
              }),
            ),
            ChoiceChip(
              label: const Text('تقسيم بالغرف'),
              selected: _splitMode == SplitBillMode.byItem,
              onSelected: (_) => setState(() {
                _splitMode = SplitBillMode.byItem;
                _initSplitByItem(cart);
              }),
            ),
            ChoiceChip(
              label: const Text('مبلغ مخصص'),
              selected: _splitMode == SplitBillMode.custom,
              onSelected: (_) => setState(() {
                _splitMode = SplitBillMode.custom;
                _initSplitBill();
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_splitMode == SplitBillMode.equal) ...[
          _label('عدد الأشخاص'),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _splitCount > 2
                    ? () => setState(() {
                          _splitCount--;
                          _initSplitBill();
                        })
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Text(
                  '$_splitCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: _splitCount < 20
                    ? () => setState(() {
                          _splitCount++;
                          _initSplitBill();
                        })
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  'كل شخص يدفع',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.money(total / _splitCount),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_splitMode == SplitBillMode.byItem) ...[
          _label('اختر الأصناف لكل شخص'),
          const SizedBox(height: 8),
          _buildItemSplitList(cart),
        ] else ...[
          _label('المبالغ المخصصة'),
          const SizedBox(height: 8),
          _buildCustomSplitList(total),
        ],
        const SizedBox(height: 16),
        _totals(cart),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _confirmSplitBill,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_saving ? 'جارٍ الحفظ...' : 'تأكيد التقسيم'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  void _initSplitByItem(CartState cart) {
    _splitItemIndices.clear();
    _splitAmounts.clear();
    final total = cart.subtotal - _discount + _tip;
    for (int i = 0; i < _splitCount; i++) {
      _splitItemIndices.add({});
      _splitAmounts.add(total / _splitCount);
    }
  }

  Widget _buildItemSplitList(CartState cart) {
    final lines = cart.lines;
    return Column(
      children: List.generate(_splitCount, (personIdx) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الشخص ${personIdx + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(lines.length, (itemIdx) {
                  final line = lines[itemIdx];
                  final isSelected =
                      _splitItemIndices[personIdx].contains(itemIdx);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _splitItemIndices[personIdx].add(itemIdx);
                        } else {
                          _splitItemIndices[personIdx].remove(itemIdx);
                        }
                      });
                    },
                    title: Text(
                      '${line.product.name} x${line.quantity}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      AppFormatters.money(line.subtotal),
                      style: const TextStyle(fontSize: 12),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.info,
                  );
                }),
                const Divider(),
                Text(
                  'الإجمالي: ${AppFormatters.money(_calculatePersonTotal(personIdx, cart))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  double _calculatePersonTotal(int personIdx, CartState cart) {
    final lines = cart.lines;
    double sum = 0;
    for (final itemIdx in _splitItemIndices[personIdx]) {
      if (itemIdx < lines.length) {
        sum += lines[itemIdx].subtotal;
      }
    }
    return sum;
  }

  Widget _buildCustomSplitList(double total) {
    while (_splitAmounts.length < _splitCount) {
      _splitAmounts.add(total / _splitCount);
    }
    return Column(
      children: List.generate(_splitCount, (idx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'الشخص ${idx + 1}',
              prefixIcon: const Icon(Icons.person_outline),
              suffixText: 'ر.س',
            ),
            onChanged: (val) {
              final v = double.tryParse(val) ?? 0;
              setState(() {
                if (idx < _splitAmounts.length) {
                  _splitAmounts[idx] = v;
                } else {
                  _splitAmounts.add(v);
                }
              });
            },
          ),
        );
      }),
    );
  }

  Future<void> _confirmSplitBill() async {
    final cart = context.read<CartCubit>();
    final cartState = cart.state;
    final discount = _discount;
    final tip = _tip;
    final net = cartState.subtotal - discount + tip;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      List<double> amounts;
      if (_splitMode == SplitBillMode.equal) {
        final each = net / _splitCount;
        amounts = List.filled(_splitCount, each);
      } else if (_splitMode == SplitBillMode.byItem) {
        amounts = [];
        for (int i = 0; i < _splitCount; i++) {
          amounts.add(_calculatePersonTotal(i, cartState));
        }
        final assigned = amounts.fold(0.0, (s, v) => s + v);
        final diff = net - assigned;
        if (diff.abs() > 0.01) {
          amounts[0] += diff;
        }
      } else {
        amounts = List.from(_splitAmounts);
        final assigned = amounts.fold(0.0, (s, v) => s + v);
        final diff = net - assigned;
        if (diff.abs() > 0.01) {
          amounts[0] += diff;
        }
      }

      final cashierName =
          context.read<AuthCubit>().state.admin?.username ?? '';
      final taxRate = context.read<SettingsCubit>().state.settings.taxRate;
      final sale = await cart.completeSplitBill(
        amounts: amounts,
        cashierName: cashierName,
        taxRate: taxRate,
        discount: discount,
        tip: tip,
        paymentMethod: _paymentMethod,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(sale);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = safeErrorMessage('حدث خطأ أثناء الحفظ', e);
        });
      }
    }
  }

  // ── مكونات مشتركة ───────────────────────────────────────

  Widget _stepHeader({
    required String title,
    required VoidCallback onBack,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _tableOrPersonCard({
    required String label,
    required IconData icon,
    required bool isOccupied,
    required Color color,
    VoidCallback? onTap,
  }) {
    final bgColor = isOccupied ? AppColors.error.withValues(alpha: 0.10) : color.withValues(alpha: 0.06);
    final borderColor = isOccupied ? AppColors.error.withValues(alpha: 0.40) : color.withValues(alpha: 0.25);
    final iconColor = isOccupied ? AppColors.error : color;
    final textColor = isOccupied ? AppColors.error : color;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isOccupied) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'مشغولة',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyListMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }

  Widget _totals(CartState cart) {
    final discount = _discount;
    final net = cart.subtotal - discount;
    final tip = _tip;
    final totalWithTip = net + tip;
    final taxRate = context.read<SettingsCubit>().state.settings.taxRate;
    final tax = taxRate <= 0 ? 0.0 : net * taxRate / (100 + taxRate);

    double? changeDue;
    double? cardPortion;
    double? shortAmount;
    if (_step == _CheckoutStep.normalPayment) {
      if (_paymentMethod == PaymentMethod.mixed) {
        final cash = _tenderedInput;
        if (cash != null && cash < totalWithTip) {
          cardPortion = totalWithTip - cash;
        }
      } else if (PaymentMethod.paidNow.contains(_paymentMethod)) {
        final tendered = _tenderedInput;
        if (tendered != null && tendered >= totalWithTip) {
          changeDue = tendered - totalWithTip;
        } else if (tendered != null && tendered < totalWithTip) {
          shortAmount = totalWithTip - tendered;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _totalRow('إجمالي الأصناف', cart.subtotal),
          if (discount > 0)
            _totalRow('الخصم', -discount, highlight: AppColors.error),
          if (tax > 0)
            _totalRow(
                'قيمة الضريبة (${AppFormatters.percent(taxRate)})', tax),
          if (tip > 0)
            _totalRow('بقشيش', tip, highlight: AppColors.accent),
          if (cardPortion != null) ...[
            const SizedBox(height: 4),
            _totalRow('الجزء نقدًا', totalWithTip - cardPortion),
            _totalRow('الجزء بالشبكة', cardPortion),
          ],
          if (shortAmount != null) ...[
            const SizedBox(height: 4),
            _totalRow('المتبقي', shortAmount, highlight: AppColors.warning),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الصافي',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                AppFormatters.money(totalWithTip),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (changeDue != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'الباقي للعميل: ${AppFormatters.money(changeDue)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
          if (tax > 0) ...[
            const SizedBox(height: 2),
            Text(
              'شامل ضريبة القيمة المضافة',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {Color? highlight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            AppFormatters.money(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
