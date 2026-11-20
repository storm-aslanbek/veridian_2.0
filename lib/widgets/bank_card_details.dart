import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

import '../models/card.dart';
import 'banking_panel.dart';

void showBankCardDetails(BuildContext context, BankCard card) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _BankCardDetails(card: card),
  );
}

class _BankCardDetails extends StatefulWidget {
  const _BankCardDetails({required this.card});
  final BankCard card;

  @override
  State<_BankCardDetails> createState() => _BankCardDetailsState();
}

class _BankCardDetailsState extends State<_BankCardDetails> {
  bool _cvcVisible = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BankingHeading(uiText('Реквизиты карты')),
            BankingPanel(
              padding: 0,
              child: Column(
                children: [
                  ListTile(
                      title: Text(uiText('Номер карты')),
                      subtitle: Text(card.cardNumber)),
                  ListTile(
                      title: Text(uiText('Держатель')),
                      subtitle: Text(card.cardHolderName)),
                  ListTile(
                      title: Text(uiText('Срок действия')),
                      subtitle: Text(card.expiryDate)),
                  ListTile(
                    title: const Text('CVC'),
                    subtitle: Text(_cvcVisible ? card.cvv : '•••'),
                    trailing: TextButton(
                      onPressed: () =>
                          setState(() => _cvcVisible = !_cvcVisible),
                      child: Text(_cvcVisible
                          ? uiText('Скрыть CVC')
                          : uiText('Показать CVC')),
                    ),
                  ),
                  ListTile(
                      title: Text(uiText('Тип карты')),
                      subtitle: Text(cardTypeLabel(card.cardType))),
                  ListTile(
                      title: Text(uiText('Лимит расходов')),
                      subtitle: Text(bankingAmount(card.spendingLimit, 'USD'))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
