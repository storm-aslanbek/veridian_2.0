import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/assistant.dart';
import '../models/payment.dart';
import '../screens/auth/demo_session.dart';
import '../services/assistant_service.dart';
import '../services/ui_strings.dart';

Future<bool> confirmPayment(
  BuildContext context, {
  required String kind,
  required double amount,
  required String accountId,
  String? brand,
}) async {
  if (isBankingDemo(context)) return true;
  final warnings = await context
      .read<AssistantService>()
      .check(kind: kind, amount: amount, accountId: accountId, brand: brand);
  if (warnings.isEmpty || !context.mounted) return true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, size: 36),
      title: Text(uiText('Проверьте операцию')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_describe(warning)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(uiText('Отмена')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(uiText('Продолжить')),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

String _describe(PaymentWarning warning) {
  final percent = warning.percent?.round();
  final category = brandCategoryLabel(warning.category ?? '');
  return switch (warning.code) {
    'large_vs_salary' => uiText('Это {0}% вашей зарплаты.', percent),
    'large_vs_balance' => uiText('Это {0}% остатка на счёте.', percent),
    'unusual_amount' => uiText('Сумма намного больше ваших обычных операций.'),
    'limit_warning' =>
      '$category: ${uiText('будет израсходовано {0}% лимита.', percent)}',
    'limit_exceeded' => '$category: ${uiText('лимит будет превышен.')}',
    _ => uiText('Необычная операция.'),
  };
}
