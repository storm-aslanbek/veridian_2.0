import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/payment.dart';
import '../services/localization_service.dart';
import 'banking_panel.dart';

class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final locale = LocalizationService().getLocaleCode();
    final date = DateFormat('d MMMM yyyy, HH:mm', locale).format(payment.date);
    final unread = !payment.isRead;
    final amountColor = payment.isIncome
        ? Colors.green.shade600
        : Theme.of(context).colorScheme.onSurface;
    return BankingPanel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: BankingIcon(
          _icon(payment),
          tone: payment.isIncome ? BankingTone.emerald : BankingTone.blue,
        ),
        title: Text(
          _title(payment),
          style:
              TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600),
        ),
        subtitle: Text(date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${payment.isIncome ? '+' : '−'}${bankingAmount(payment.price)}',
              style: TextStyle(fontWeight: FontWeight.w700, color: amountColor),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Icon(Icons.circle,
                  size: 10, color: Theme.of(context).colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }

  String _title(Payment payment) => switch (payment.type) {
        'transfer_out' => '${uiText('Перевод')} · ${payment.counterparty}',
        'transfer_in' =>
          uiText('Поступление от {0}', payment.counterparty),
        'salary' => '${uiText('Зарплата')} · ${payment.counterparty}',
        _ => '${uiText('Оплата')} · ${payment.counterparty}',
      };

  IconData _icon(Payment payment) => switch (payment.type) {
        'transfer_out' => Icons.north_east_rounded,
        'transfer_in' => Icons.south_west_rounded,
        'salary' => Icons.account_balance_wallet_rounded,
        _ => paymentCategoryIcon(payment.category),
      };
}

IconData paymentCategoryIcon(String category) => switch (category) {
      'entertainment' => Icons.movie_rounded,
      'food' => Icons.restaurant_rounded,
      'groceries' => Icons.shopping_basket_rounded,
      'services' => Icons.miscellaneous_services_rounded,
      'subscriptions' => Icons.subscriptions_rounded,
      _ => Icons.payments_rounded,
    };
