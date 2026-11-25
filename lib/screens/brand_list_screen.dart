import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bank_account.dart';
import '../models/payment.dart';
import '../services/account_service.dart';
import '../services/payment_service.dart';
import '../widgets/banking_panel.dart';
import '../widgets/payment_warning_dialog.dart';

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({super.key, required this.category});

  final String category;

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  String _query = '';
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    context.read<PaymentService>().loadBrands();
  }

  List<Brand> _visibleBrands(List<Brand> brands) => brands
      .where((brand) =>
          brand.category == widget.category &&
          brand.name.toLowerCase().contains(_query))
      .toList();

  Future<void> _pay(Brand brand) async {
    if (_paying) return;
    _paying = true;
    try {
      await _requestPayment(brand);
    } finally {
      _paying = false;
    }
  }

  Future<void> _requestPayment(Brand brand) async {
    final accounts = context.read<AccountService>().accounts;
    if (accounts.isEmpty) {
      bankingNotice(context, uiText('Нет доступных счетов'));
      return;
    }
    final price = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PriceSheet(brand: brand),
    );
    if (price == null || !mounted) return;
    final account = accounts.first;
    final confirmed = await confirmPayment(context,
        kind: 'purchase',
        amount: price,
        accountId: account.id,
        brand: brand.name);
    if (!confirmed || !mounted) return;
    await _completePurchase(brand, price, account);
  }

  Future<void> _completePurchase(
      Brand brand, double price, BankAccount account) async {
    final paid = await context.read<PaymentService>().purchase(
          accountId: account.id,
          brand: brand.name,
          price: price,
        );
    if (!mounted) return;
    if (paid) {
      await context.read<AccountService>().refreshAccount(account.id);
    }
    if (!mounted) return;
    bankingNotice(
      context,
      paid
          ? '${uiText('Оплата')} ${bankingAmount(price)} · ${brand.name}'
          : uiText('Не удалось выполнить оплату'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = _visibleBrands(context.watch<PaymentService>().brands);
    return Scaffold(
      appBar: AppBar(title: Text(brandCategoryLabel(widget.category))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: uiText('Поиск бренда'),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: brands.length,
              itemBuilder: (_, index) => ListTile(
                title: Text(brands[index].name),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pay(brands[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.brand});

  final Brand brand;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  final _controller = TextEditingController();

  double? get _price => double.tryParse(_controller.text.replaceAll(',', '.'));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = _price;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.brand.name,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            ],
            decoration:
                InputDecoration(labelText: uiText('Сумма'), suffixText: '₸'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: price != null && price > 0
                ? () => Navigator.pop(context, price)
                : null,
            child: Text(uiText('Оплатить')),
          ),
        ],
      ),
    );
  }
}
