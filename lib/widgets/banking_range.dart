import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

import '../models/transaction.dart';

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

