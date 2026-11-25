import 'package:veridian/services/ui_strings.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/account_service.dart';
import '../services/local_storage_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';
import '../widgets/banking_panel.dart';
import '../widgets/banking_range.dart';
import 'messages_screen.dart';

const analyticsColors = [
  Color(0xFF00A87E),
  Color(0xFF498BE8),
  Color(0xFFE49845),
  Color(0xFFB657A1),
  Color(0xFF7764CC),
  Color(0xFF398787),
];

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.hideBalance = false});
  final bool hideBalance;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _period = 0;
  bool _income = false;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserService>().currentUser?.id;
    final accounts = context.watch<AccountService>().accounts.where(
        (account) => account.userId == userId && account.currency == 'KZT');
    final operations = context.watch<TransactionService>().transactions.where(
        (operation) =>
            operation.userId == userId &&
            operation.currency == 'KZT' &&
            operation.status == 'completed' &&
            !operation.accountId.startsWith('sample-account-id'));
    final now = DateTime.now();
    final budget = LocalStorageService.getDouble(_budgetKey(userId, now));
    final monthStart = DateTime(now.year, now.month);
    final today = DateUtils.dateOnly(now);
    final range = switch (_period) {
      1 => DateTimeRange(start: today, end: today),
      2 => _customRange!,
      _ => DateTimeRange(start: monthStart, end: today),
    };

    final totals = <String, double>{};
    for (final item in operations) {
      if (item.type != (_income ? 'credit' : 'debit') ||
          !matchesBankingRange(item, range)) {
        continue;
      }
      totals.update(item.category, (value) => value + item.amount.abs(),
          ifAbsent: () => item.amount.abs());
    }
    final categories = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = totals.values.fold<double>(0, (sum, amount) => sum + amount);
    final spent = operations
        .where((operation) =>
            operation.type == 'debit' &&
            !operation.transactionDate.toLocal().isBefore(monthStart))
        .fold<double>(0, (sum, operation) => sum + operation.amount.abs());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(uiText('Аналитика'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BankingPanel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BankingIcon(Icons.account_balance_wallet_outlined),
              const SizedBox(height: 12),
              Text(uiText('Всего в Veridian')),
              Text(
                widget.hideBalance
                    ? '•••• ₸'
                    : accounts.isEmpty
                        ? '— ₸'
                        : bankingAmount(accounts.fold<double>(
                            0, (sum, account) => sum + account.balance)),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(uiText('Счета в тенге')),
            ]),
          ),
          const SizedBox(height: 22),
          BankingHeading(uiText('Анализ операций')),
          Wrap(
            spacing: 7,
            children: [
              for (final (index, label) in [
                uiText('За месяц'),
                uiText('За день'),
                uiText('Период')
              ].indexed)
                ChoiceChip(
                  label: Text(index == 2 && _period == 2
                      ? formatBankingRange(context, _customRange!)
                      : label),
                  selected: _period == index,
                  onSelected: (_) async {
                    if (index != 2) {
                      setState(() => _period = index);
                      return;
                    }
                    final selected =
                        await pickBankingRange(context, _customRange);
                    if (selected != null && mounted) {
                      setState(() {
                        _customRange = selected;
                        _period = index;
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(uiText('Расходы'))),
              ButtonSegment(value: true, label: Text(uiText('Доходы'))),
            ],
            selected: {_income},
            onSelectionChanged: (value) =>
                setState(() => _income = value.single),
          ),
          const SizedBox(height: 12),
          BankingPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_income ? uiText('Доходы') : uiText('Расходы')),
                      Text(bankingAmount(total),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  )),
                  SizedBox.square(
                    dimension: 92,
                    child: CustomPaint(
                      painter: _CategoryRing(
                        categories.map((entry) => entry.value).toList(),
                        total,
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                if (total == 0)
                  Text(uiText(
                      'За выбранный период нет подтверждённых операций в тенге.')),
                Wrap(
                  spacing: 5,
                  runSpacing: 6,
                  children: [
                    for (final (index, entry) in categories.indexed)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: CircleAvatar(
                            backgroundColor: analyticsColors[
                                index % analyticsColors.length]),
                        label: Text(
                            '${bankingCategory(entry.key)} · ${bankingAmount(entry.value)}'),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => openBankingScreen<void>(
                      context, const MessagesScreen()),
                  child: Text(uiText('Смотреть операции')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BankingHeading(uiText('Бюджет на месяц')),
          BankingPanel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  budget == null
                      ? uiText('Лимит пока не установлен')
                      : bankingAmount(budget),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (budget != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                    value: (spent / budget).clamp(0.0, 1.0)),
                const SizedBox(height: 8),
                Text(uiText('Потрачено {0}', bankingAmount(spent))),
              ],
              if (userId != null)
                TextButton(
                  onPressed: () => _editBudget(userId, now, budget),
                  child: Text(budget == null
                      ? uiText('Установить лимит')
                      : uiText('Изменить лимит')),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  String _budgetKey(String? userId, DateTime month) =>
      'ui_monthly_budget_${userId}_${month.year}_${month.month}';

  Future<void> _editBudget(
      String userId, DateTime month, double? existing) async {
    final form = GlobalKey<FormState>();
    double? value = existing;
    final selected = await showDialog<double>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(uiText('Лимит на месяц')),
        content: Form(
          key: form,
          child: TextFormField(
            autofocus: true,
            initialValue: existing?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                InputDecoration(suffixText: '₸', labelText: uiText('Сумма')),
            onChanged: (text) =>
                value = double.tryParse(text.replaceAll(',', '.')),
            validator: (_) => value == null || !value!.isFinite || value! <= 0
                ? uiText('Введите сумму больше нуля')
                : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(uiText('Отмена'))),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(dialog, value);
            },
            child: Text(uiText('Сохранить')),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final saved = await LocalStorageService.saveDouble(
        _budgetKey(userId, month), selected);
    if (!mounted) return;
    if (saved) {
      setState(() {});
    } else {
      bankingNotice(
          context, uiText('Не удалось сохранить лимит на этом устройстве.'));
    }
  }
}

class _CategoryRing extends CustomPainter {
  const _CategoryRing(this.values, this.total, this.track);
  final List<double> values;
  final double total;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(9);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..color = track;
    canvas.drawOval(bounds, paint);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final (index, value) in values.indexed) {
      final sweep = 2 * math.pi * value / total;
      final gap = values.length == 1 ? 0.0 : math.min(.055, sweep / 3);
      paint.color = analyticsColors[index % analyticsColors.length];
      canvas.drawArc(bounds, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_CategoryRing oldDelegate) =>
      oldDelegate.values != values || oldDelegate.track != track;
}
