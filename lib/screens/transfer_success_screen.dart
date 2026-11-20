import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

import '../widgets/banking_panel.dart';

class TransferSuccessScreen extends StatelessWidget {
  const TransferSuccessScreen({
    super.key,
    required this.amount,
    required this.recipientName,
    this.currency = 'KZT',
    this.homeActionAvailable = false,
  });

  final double amount;
  final String recipientName;
  final String currency;
  final bool homeActionAvailable;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const Align(child: BankingIcon(Icons.check_rounded, size: 64)),
              const SizedBox(height: 20),
              Text(uiText('Перевод выполнен!'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 22),
              BankingPanel(
                padding: 0,
                child: Column(children: [
                  ListTile(
                      title: Text(uiText('Получатель')),
                      subtitle: Text(recipientName)),
                  ListTile(
                      title: Text(uiText('Сумма')),
                      subtitle: Text(bankingAmount(amount, currency))),
                ]),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(homeActionAvailable
                    ? uiText('Вернуться на главную')
                    : uiText('Готово')),
              ),
            ],
          ),
        ),
      );
}
