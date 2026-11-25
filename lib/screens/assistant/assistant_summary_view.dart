import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/assistant.dart';
import '../../models/payment.dart';
import '../../services/ui_strings.dart';
import '../../widgets/ai/ai_effects.dart';
import '../../widgets/banking_panel.dart';

class AssistantSummaryView extends StatelessWidget {
  const AssistantSummaryView({super.key, required this.summary});

  final AssistantSummary summary;

  @override
  Widget build(BuildContext context) {
    final sections = [
      _spendingPower(context),
      _section(uiText('Остаток и прогноз'), _balance()),
      _section(uiText('Расходы по категориям'), _categories()),
      if (summary.topCategories.isNotEmpty)
        _section(uiText('Больше всего расходов'), _topCategories()),
      _section(uiText('Сравнение с прошлым месяцем'), _comparison()),
      if (summary.subscriptions.isNotEmpty)
        _section(uiText('Подписки'), _subscriptions()),
      if (summary.limits.isNotEmpty)
        _section(uiText('Лимиты'), _limits(context)),
      if (summary.goal != null)
        _section(uiText('Цель накопления'), _goal(summary.goal!)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, section) in sections.indexed)
          FadeSlideIn(order: index, child: section),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: BankingPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [BankingHeading(title), ...children],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _spendingPower(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: aiGradient, borderRadius: BorderRadius.circular(24)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(uiText('Можно тратить в день')),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: summary.perDay),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text(
                bankingAmount(value.roundToDouble()),
                style: theme.displaySmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Text(uiText('Дней до конца месяца: {0}', summary.daysLeft)),
          ],
        ),
      ),
    );
  }

  List<Widget> _balance() => [
        _row(uiText('Зарплата'), bankingAmount(summary.salary)),
        _row(uiText('Расходы'), bankingAmount(summary.totalExpenses)),
        _row(uiText('Переводы'), bankingAmount(summary.transfersOut)),
        _row(uiText('Остаток от зарплаты'), bankingAmount(summary.salaryLeft)),
        _row(uiText('Прогноз расходов за месяц'),
            bankingAmount(summary.forecastExpenses)),
        _row(uiText('Прогноз остатка'), bankingAmount(summary.forecastLeft)),
        if (summary.lowConfidence)
          Text(uiText('В начале месяца прогноз неточный.')),
      ];

  List<Widget> _categories() => [
        for (final item in summary.categories)
          _row(brandCategoryLabel(item.category), bankingAmount(item.amount)),
      ];

  List<Widget> _topCategories() => [
        for (final item in summary.topCategories) ...[
          _row(brandCategoryLabel(item.category), '${item.percent}%'),
          LinearProgressIndicator(value: item.percent / 100),
          const SizedBox(height: 8),
        ],
      ];

  List<Widget> _comparison() {
    final change = summary.changePercent;
    return [
      _row(uiText('За те же дни (1–{0})', summary.cutoffDay),
          bankingAmount(summary.previousSamePeriod)),
      _row(
          uiText('За весь прошлый месяц'), bankingAmount(summary.previousFull)),
      _row(uiText('Сейчас'), bankingAmount(summary.totalExpenses)),
      const SizedBox(height: 4),
      Text(change == null
          ? uiText('Не с чем сравнить.')
          : '${uiText(summary.difference > 0 ? 'Расходы выросли' : 'Расходы не выросли')}: '
              '${bankingAmount(summary.difference.abs())} (${change.abs()}%)'),
    ];
  }

  List<Widget> _subscriptions() => [
        for (final item in summary.subscriptions)
          _row(
            '${item.brand} · ${DateFormat('dd.MM').format(item.nextChargeDate)}'
            '${item.overdue ? ' · ${uiText('ожидается')}' : ''}',
            bankingAmount(item.price),
          ),
        const Divider(height: 16),
        _row(uiText('В месяц'), bankingAmount(summary.subscriptionsMonthly)),
        _row(uiText('В год'), bankingAmount(summary.subscriptionsYearly)),
      ];

  List<Widget> _limits(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return [
      for (final item in summary.limits) ...[
        _row(brandCategoryLabel(item.category),
            '${bankingAmount(item.spent)} / ${bankingAmount(item.limit)}'),
        LinearProgressIndicator(
          value: (item.percent / 100).clamp(0, 1).toDouble(),
          color: switch (item.status) {
            'exceeded' => colors.error,
            'warning' => Colors.orange,
            _ => colors.primary,
          },
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _goal(GoalProgress progress) => [
        _row(uiText('Накоплено'),
            '${bankingAmount(progress.goal.savedAmount)} / ${bankingAmount(progress.goal.amount)}'),
        _row(uiText('Откладывать в месяц'),
            bankingAmount(progress.requiredMonthly)),
        _row(uiText('Месяцев осталось'), '${progress.monthsLeft}'),
        Text(uiText(switch (progress.status) {
          'achieved' => 'Цель достигнута.',
          'expired' => 'Срок цели прошёл.',
          'on_track' => 'Вы успеваете.',
          _ => 'При таких расходах вы не успеваете.',
        })),
      ];
}
