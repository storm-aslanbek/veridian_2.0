import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/localization_service.dart';
import 'package:veridian/theme.dart';

class BalanceDisplay extends StatelessWidget {
  final double balance;
  final String? label;
  final bool isLarge;

  const BalanceDisplay({
    super.key,
    required this.balance,
    this.label,
    this.isLarge = true,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        symbol: '',
        decimalDigits: 2,
        locale: Localizations.localeOf(context).languageCode);
    final formattedBalance = "${currencyFormat.format(balance)} ₸";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? LocalizationService().translate('total_balance'),
          style: (isLarge
                  ? context.textStyles.bodyMedium
                  : context.textStyles.bodySmall)
              ?.withColor(
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedBalance,
          style: (isLarge
                  ? context.textStyles.displaySmall
                  : context.textStyles.headlineSmall)
              ?.bold
              .withColor(
                Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
