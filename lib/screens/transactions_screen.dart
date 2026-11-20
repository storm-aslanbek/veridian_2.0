import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/localization_provider.dart';
import '../services/account_service.dart';
import '../services/card_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';
import '../widgets/banking_panel.dart';

bool matchesBankingRange(Transaction item, DateTimeRange range) {
  final date = DateUtils.dateOnly(item.transactionDate.toLocal());
  return !date.isBefore(range.start) && !date.isAfter(range.end);
}

String formatBankingRange(BuildContext context, DateTimeRange range) {
  final format = MaterialLocalizations.of(context).formatCompactDate;
  return '${format(range.start)} – ${format(range.end)}';
}

Future<DateTimeRange?> pickBankingRange(
        BuildContext context, DateTimeRange? initial) =>
    showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDateRange: initial,
      helpText: uiText('Период операций'),
      saveText: uiText('Применить'),
      cancelText: uiText('Отмена'),
      confirmText: uiText('Готово'),
    );

String bankingCategory(String category) => switch (category.toLowerCase()) {
      'transfer' => uiText('Переводы'),
      'utilities' => uiText('Коммунальные услуги'),
      'food' => uiText('Продукты'),
      'salary' => uiText('Зарплата'),
      'transport' => uiText('Транспорт'),
      'entertainment' => uiText('Развлечения'),
      _ => uiText(category),
    };

String _transactionTitle(Transaction item) {
  final recipient = item.recipient;
  if (recipient == null) return bankingCategory(item.category);
  return item.userId == 'veridian-demo' ? uiText(recipient) : recipient;
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.initialRange});
  final DateTimeRange? initialRange;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();
  bool _searching = false;
  DateTimeRange? _range;
  String? _category;
  String? _account;

  @override
  void initState() {
    super.initState();
    _range = widget.initialRange;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserService>().currentUser?.id;
    final language = context.watch<LocalizationProvider>();
    final transactions = context
        .watch<TransactionService>()
        .transactions
        .where((item) => item.userId == userId)
        .toList();
    final categories = {
      for (final item in transactions)
        item.category: bankingCategory(item.category)
    };
    final accounts = {
      for (final item in context
          .watch<AccountService>()
          .accounts
          .where((item) => item.userId == userId))
        item.id: item.userId == 'veridian-demo'
            ? uiText(item.accountName)
            : item.accountName,
      for (final item in context
          .watch<CardService>()
          .cards
          .where((item) => item.userId == userId))
        item.accountId: item.maskedCardNumber,
    };
    final query = _search.text.trim().toLowerCase();
    final filtered = transactions
        .where(
          (item) =>
              (_category == null || item.category == _category) &&
              (_account == null || item.accountId == _account) &&
              (_range == null || matchesBankingRange(item, _range!)) &&
              '${_transactionTitle(item)} ${item.description ?? ''} ${bankingCategory(item.category)}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final grouped = <DateTime, List<Transaction>>{};
    for (final item in filtered) {
      grouped
          .putIfAbsent(
              DateUtils.dateOnly(item.transactionDate.toLocal()), () => [])
          .add(item);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(language.translate('history')),
        actions: [
          IconButton(
            tooltip: _searching ? uiText('Закрыть поиск') : uiText('Поиск'),
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _search.clear();
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_searching)
            TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                  hintText: uiText('Поиск операций'),
                  prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (_) => setState(() {}),
            ),
          Wrap(
            spacing: 7,
            children: [
              InputChip(
                label: Text(_range == null
                    ? uiText('Период')
                    : formatBankingRange(context, _range!)),
                selected: _range != null,
                onDeleted:
                    _range == null ? null : () => setState(() => _range = null),
                onPressed: () async {
                  final result = await pickBankingRange(context, _range);
                  if (result != null && mounted)
                    setState(() => _range = result);
                },
              ),
              _filter(uiText('Категории'), categories, _category,
                  (value) => setState(() => _category = value)),
              _filter(uiText('Карты и счета'), accounts, _account,
                  (value) => setState(() => _account = value)),
            ],
          ),
          const SizedBox(height: 10),
          Text(uiText('Операции на этом устройстве')),
          const SizedBox(height: 10),
          if (grouped.isEmpty)
            BankingPanel(child: Text(uiText('Операции не найдены'))),
          for (final entry in grouped.entries) ...[
            BankingHeading(
                MaterialLocalizations.of(context).formatMediumDate(entry.key)),
            BankingPanel(
                padding: 0,
                child: Column(children: [
                  for (final item in entry.value)
                    ListTile(
                      leading: BankingIcon(item.type == 'credit'
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded),
                      title: Text(_transactionTitle(item)),
                      subtitle: Text(item.accountId
                              .startsWith('sample-account-id')
                          ? uiText('{0} · Демо', bankingCategory(item.category))
                          : bankingCategory(item.category)),
                      trailing: Text(
                        '${item.type == 'credit' ? '+' : '−'}${bankingAmount(item.amount.abs(), item.currency)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ])),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  Widget _filter(String title, Map<String, String> items, String? selected,
          ValueChanged<String?> onChange) =>
      PopupMenuButton<String>(
        tooltip: title,
        onSelected: (value) => onChange(value.isEmpty ? null : value),
        itemBuilder: (_) => [
          PopupMenuItem(value: '', child: Text(uiText('Все'))),
          for (final entry in items.entries)
            PopupMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        child: Chip(
          label: Text(items[selected] ?? title),
          avatar: const Icon(Icons.expand_more_rounded, size: 17),
        ),
      );
}
