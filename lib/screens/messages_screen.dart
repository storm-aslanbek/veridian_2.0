import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

import '../widgets/banking_panel.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(uiText('Уведомления'))),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: BankingPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: BankingIcon(Icons.notifications_none_rounded),
              title: Text(uiText('Новых уведомлений нет')),
            ),
          ),
        ),
      );
}
