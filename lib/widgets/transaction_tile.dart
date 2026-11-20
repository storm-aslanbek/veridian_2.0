import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Добавлено для доступа к провайдеру
import 'package:veridian/models/transaction.dart';
import 'package:veridian/providers/localization_provider.dart'; // Добавлено
import 'package:veridian/theme.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Получаем доступ к локализации
    final localization = context.watch<LocalizationProvider>();
    final theme = Theme.of(context);

    final currencyFormat = NumberFormat.currency(
        symbol: '',
        decimalDigits: 2,
        locale: Localizations.localeOf(context).languageCode);
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    final isDebit = transaction.type == 'debit';
    final sign = isDebit ? '-' : '+';
    final formattedAmount =
        "$sign${currencyFormat.format(transaction.amount.abs())} ₸";

    // Переводим категорию для отображения
    // Например: "Shopping" -> "cat_shopping" -> 'Покупки' (из словаря)
    final categoryKey = 'cat_${transaction.category.toLowerCase()}';
    String displayCategory = localization.translate(categoryKey);

    // Если перевода нет (вернулся сам ключ), показываем оригинал
    if (displayCategory == categoryKey) {
      displayCategory = transaction.category;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getCategoryIcon(),
                  color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.recipient ?? displayCategory,
                      style: context.textStyles.bodyMedium?.semiBold
                          .withColor(theme.colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                      '$displayCategory · ${dateFormat.format(transaction.transactionDate)}',
                      style: context.textStyles.bodySmall
                          ?.withColor(theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(formattedAmount,
                style: context.textStyles.bodyMedium?.semiBold.withColor(
                  isDebit ? theme.colorScheme.error : theme.colorScheme.primary,
                )),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (transaction.category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'utilities':
        return Icons.lightbulb;
      case 'entertainment':
        return Icons.movie;
      case 'salary':
        return Icons.account_balance_wallet;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }
}
