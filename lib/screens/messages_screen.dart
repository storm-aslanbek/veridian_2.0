import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';
import '../widgets/banking_panel.dart';
import '../widgets/payment_tile.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  MessageKind? _kind;

  static const _kindLabels = <MessageKind, String>{
    MessageKind.purchase: 'Платежи',
    MessageKind.transfer: 'Переводы',
    MessageKind.salary: 'Зарплата',
  };

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PaymentService>();
    final payments = service.payments
        .where((payment) => _kind == null || payment.kind == _kind)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(uiText('Сообщения')),
        actions: [
          if (service.unreadCount > 0)
            IconButton(
              tooltip: uiText('Прочитать все'),
              onPressed: service.markAllRead,
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                _KindChip(
                  label: uiText('Все'),
                  selected: _kind == null,
                  onTap: () => setState(() => _kind = null),
                ),
                for (final entry in _kindLabels.entries)
                  _KindChip(
                    label: uiText(entry.value),
                    selected: _kind == entry.key,
                    onTap: () => setState(() => _kind = entry.key),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: service.loadPayments,
              child: payments.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        BankingPanel(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const BankingIcon(
                                Icons.notifications_none_rounded),
                            title: Text(uiText('Сообщений пока нет')),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) =>
                          PaymentTile(payment: payments[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
            label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
