import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/account_service.dart';
import '../services/user_service.dart';
import '../widgets/banking_panel.dart';
import 'auth/demo_session.dart';

enum BankingOperation { payment, topUp, ownTransfer, international }

class BankingOperationForm extends StatefulWidget {
  const BankingOperationForm(
      {super.key,
      required this.operation,
      required this.title,
      this.initialAccountId,
      this.embedded = false});
  final BankingOperation operation;
  final String title;
  final String? initialAccountId;
  final bool embedded;

  @override
  State<BankingOperationForm> createState() => _BankingOperationFormState();
}

class _BankingOperationFormState extends State<BankingOperationForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _recipient = TextEditingController();
  String? _source;
  String? _target;
  String? _status;

  bool get _topUp => widget.operation == BankingOperation.topUp;
  bool get _own => widget.operation == BankingOperation.ownTransfer;
  bool get _international => widget.operation == BankingOperation.international;

  @override
  void initState() {
    super.initState();
    _source = widget.initialAccountId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _recipient.dispose();
    super.dispose();
  }

  void _submit(DemoAccounts? demo, String? source) {
    if (!_form.currentState!.validate() || source == null) return;
    if (demo == null) {
      setState(() => _status =
          'Реквизиты проверены. Чтобы отправить операцию, требуется подключение этого направления к банку.');
      return;
    }
    final amount = double.parse(_amount.text.replaceAll(',', '.'));
    final completed = demo.apply(context, source, _topUp ? amount : -amount,
        destinationId: _own ? _target : null,
        description: widget.title,
        category: _topUp
            ? 'Пополнение'
            : _own || _international
                ? 'Transfer'
                : 'Оплата услуг');
    if (!completed) {
      setState(() => _status = 'Проверьте остаток и выбранные счета.');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(uiText('Демо-операция выполнена'))),
    );
    if (widget.embedded) {
      _amount.clear();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final demo = context.read<DemoAccounts?>();
    final id = context.watch<UserService>().currentUser?.id;
    final accounts = context
        .watch<AccountService>()
        .accounts
        .where((account) => account.userId == id && account.isActive)
        .toList();
    final source = accounts.any((account) => account.id == _source)
        ? _source
        : accounts.firstOrNull?.id;
    final targets = accounts.where((account) => account.id != source);
    final action = _topUp
        ? uiText('Пополнить')
        : _own || _international
            ? uiText('Перевести')
            : uiText('Оплатить');
    final emerald = _topUp
        ? const Color(0xFF10B981)
        : Theme.of(context).colorScheme.primary;
    final panel = BankingPanel(
        child: Form(
      key: _form,
      onChanged: () {
        if (_status != null) setState(() => _status = null);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.embedded) BankingHeading(uiText(uiText(widget.title))),
        if (demo != null)
          Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(uiText('Демо · без реального списания'))),
        DropdownButtonFormField<String>(
          initialValue: source,
          isExpanded: true,
          decoration: InputDecoration(
              labelText:
                  _topUp ? uiText('Счёт пополнения') : uiText('Счёт списания')),
          items: [
            for (final account in accounts)
              DropdownMenuItem(
                  value: account.id,
                  child: Text(
                      demo != null
                          ? uiText(account.accountName)
                          : account.accountName,
                      overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (value) => setState(() {
            _source = value;
            _target = null;
          }),
          validator: (value) => value == null ? uiText('Выберите счёт') : null,
        ),
        if (_own) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(source),
            initialValue: _target,
            isExpanded: true,
            decoration: InputDecoration(labelText: uiText('Счёт зачисления')),
            items: [
              for (final account in targets)
                DropdownMenuItem(
                    value: account.id,
                    child: Text(
                        demo != null
                            ? uiText(account.accountName)
                            : account.accountName,
                        overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (value) => _target = value,
            validator: (value) =>
                value == null ? uiText('Выберите другой счёт') : null,
          ),
        ] else if (!_topUp) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _recipient,
            decoration: InputDecoration(
                labelText: _international
                    ? uiText('IBAN получателя')
                    : uiText('Номер телефона, договора или лицевого счёта')),
            validator: (value) {
              final text = (value ?? '').replaceAll(RegExp(r'\s+'), '');
              if (_international &&
                  !RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$')
                      .hasMatch(text.toUpperCase())) {
                return uiText('Проверьте IBAN');
              }
              return text.isEmpty ? uiText('Введите реквизиты') : null;
            },
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: uiText('Сумма'),
              suffixText:
                  accounts.where((a) => a.id == source).firstOrNull?.currency ==
                          'KZT'
                      ? '₸'
                      : accounts
                          .where((a) => a.id == source)
                          .firstOrNull
                          ?.currency),
          validator: (raw) {
            final value = double.tryParse((raw ?? '').replaceAll(',', '.'));
            return value == null || !value.isFinite || value <= 0
                ? uiText('Введите сумму больше нуля')
                : null;
          },
        ),
        const SizedBox(height: 16),
        if (_status != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(uiText(_status!))),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: emerald,
            foregroundColor: _topUp ? const Color(0xFF052E23) : null,
            minimumSize: const Size.fromHeight(46),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _submit(demo, source),
          child: Text(
              demo == null && !_topUp ? uiText('Проверить реквизиты') : action),
        ),
      ]),
    ));
    if (widget.embedded) return panel;
    return Scaffold(
      appBar: AppBar(title: Text(uiText(widget.title))),
      body: ListView(padding: const EdgeInsets.all(16), children: [panel]),
    );
  }
}
