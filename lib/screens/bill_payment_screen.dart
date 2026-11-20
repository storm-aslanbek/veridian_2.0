import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../services/account_service.dart';
import '../services/bill_service.dart';
import '../services/user_service.dart';
import '../widgets/banking_panel.dart';
import 'mobile_payment_screen.dart';
import 'support_screen.dart';
import 'auth/demo_session.dart';
import 'banking_operation_form.dart';

class BillPaymentScreen extends StatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  String _city = 'Тараз';
  String _query = '';
  bool _mine = false;
  String? _markingBillId;
  static const _sampleBills = {
    ('Power Company', 'PWR-123456'),
    ('Water Utilities', 'WTR-789012'),
    ('ISP Provider', 'ISP-345678'),
    ('Gas Company', 'GAS-567890'),
  };

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final userId = context.watch<UserService>().currentUser?.id;
    final bills = context
        .watch<BillService>()
        .bills
        .where(
          (bill) =>
              bill.userId == userId &&
              !(bill.currency == 'USD' &&
                  _sampleBills.contains((bill.provider, bill.accountNumber))) &&
              '${bill.provider} ${bill.accountNumber} ${bill.billType}'
                  .toLowerCase()
                  .contains(_query) &&
              (_mine || !bill.isPaid),
        )
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final frequent = bills.where((bill) => bill.isRecurring).take(4);

    return Scaffold(
      appBar: AppBar(
        title: Text(uiText('Платежи')),
        actions: [
          BankingCityPicker(
              city: _city, onChanged: (city) => setState(() => _city = city))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(uiText('Все'))),
              ButtonSegment(value: true, label: Text(uiText('Мои платежи'))),
            ],
            selected: {_mine},
            onSelectionChanged: (selection) =>
                setState(() => _mine = selection.single),
          ),
          const SizedBox(height: 14),
          TextField(
            decoration: InputDecoration(
                hintText: uiText('Что хотите оплатить?'),
                prefixIcon: Icon(Icons.search_rounded)),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          if (!_mine) ...[
            const SizedBox(height: 16),
            BankingPanel(
              padding: 12,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: BankingHeading(uiText('Оплата услуг'))),
                    _paymentCategories(),
                  ]),
            ),
            const SizedBox(height: 12),
            BankingOperationForm(
                operation: BankingOperation.topUp,
                title: 'Пополнить',
                embedded: true),
          ],
          if (frequent.isNotEmpty) ...[
            const SizedBox(height: 20),
            BankingHeading(uiText('Частые')),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final bill in frequent)
                  ActionChip(
                    avatar: const Icon(Icons.receipt_long_rounded, size: 17),
                    label: Text(bill.provider),
                    onPressed: () => _billDetails(bill),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          BankingHeading(
              _mine ? uiText('Мои счета') : uiText('Выставленные счета')),
          if (bills.isEmpty)
            BankingPanel(child: Text(uiText('Счета не найдены'))),
          for (final bill in bills) ...[
            BankingPanel(
                padding: 0,
                child: ListTile(
                  leading: const BankingIcon(Icons.receipt_long_rounded),
                  title: Text(bill.provider),
                  subtitle: Text(bill.isPaid
                      ? uiText('Отмечен оплаченным')
                      : uiText(
                          'До {0}',
                          MaterialLocalizations.of(context)
                              .formatCompactDate(bill.dueDate))),
                  trailing: Text(bankingAmount(bill.amount, bill.currency),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => _billDetails(bill),
                )),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          BankingHeading(uiText('Дополнительно')),
          BankingPanel(
              padding: 0,
              child: Column(children: [
                ListTile(
                  leading: const BankingIcon(Icons.qr_code_scanner_rounded),
                  title: Text(uiText('Мобильные платежи')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => isBankingDemo(context)
                      ? bankingNotice(
                          context,
                          uiText(
                              'Для камеры откройте мобильные платежи после входа.'))
                      : openBankingScreen<void>(
                          context, const MobilePaymentScreen()),
                ),
                ListTile(
                  leading: const BankingIcon(Icons.headset_mic_rounded),
                  title: Text(uiText('Связь с банком')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => isBankingDemo(context)
                      ? bankingNotice(
                          context,
                          uiText(
                              'В полной версии здесь открывается чат Veridian.'))
                      : openBankingScreen<void>(context, const SupportScreen()),
                ),
              ])),
        ],
      ),
    );
  }

  Widget _paymentCategories() {
    final entries = [
      ('Мобильная связь', Icons.phone_iphone_outlined),
      ('Коммунальные услуги', Icons.receipt_long_outlined),
      ('Интернет и ТВ', Icons.language_outlined),
      ('Транспорт', Icons.directions_bus_outlined),
      ('Развлечения', Icons.local_activity_outlined),
      ('Налоги и штрафы', Icons.account_balance_outlined),
      ('Страхование', Icons.verified_user_outlined),
      ('Кэшбэк', Icons.savings_outlined),
    ]
        .where((entry) => uiText(entry.$1).toLowerCase().contains(_query))
        .toList();
    if (entries.isEmpty)
      return Padding(
        padding: EdgeInsets.all(12),
        child: Text(uiText('Категории не найдены')),
      );
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width < 370 ? 3 : 4,
      childAspectRatio: 64 + MediaQuery.textScalerOf(context).scale(11) * 3,
      crossAxisSpacing: 4,
      mainAxisSpacing: 3,
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final (name, icon) in entries)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              openBankingScreen<void>(
                  context,
                  BankingOperationForm(
                      operation: BankingOperation.payment, title: name));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Column(children: [
                BankingIcon(icon),
                const SizedBox(height: 6),
                Flexible(
                    child: Text(uiText(name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
      ],
    );
  }

  Future<void> _billDetails(Bill bill) async {
    final shouldMark = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BankingHeading(bill.provider),
                Text(uiText('Номер счёта {0}', bill.accountNumber)),
                const SizedBox(height: 8),
                Text(bankingAmount(bill.amount, bill.currency)),
                const SizedBox(height: 12),
                Text(bill.isPaid
                    ? uiText('Отмечен оплаченным на этом устройстве.')
                    : uiText(
                        'Отметка сохранится на этом устройстве. Средства со счёта списаны не будут.')),
                if (!bill.isPaid && _markingBillId == null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: () => Navigator.pop(sheet, true),
                      child: Text(uiText('Отметить оплаченным'))),
                ],
              ]),
        ),
      ),
    );
    if (!mounted || shouldMark != true || _markingBillId != null) return;
    final users = context.read<UserService>();
    if (users.currentUser?.id != bill.userId) return;
    final accounts = context.read<AccountService>();
    final service = context.read<BillService>();
    setState(() => _markingBillId = bill.id);
    final saved = await service.payBill(bill.id);
    if (saved && users.currentUser?.id == bill.userId)
      await accounts.loadAccounts(bill.userId);
    if (!mounted) return;
    setState(() => _markingBillId = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved
          ? uiText('Отметка об оплате сохранена')
          : uiText('Не удалось сохранить отметку')),
    ));
  }
}
