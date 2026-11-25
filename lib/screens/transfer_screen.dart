import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/phone_formatter.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/payment_service.dart';
import '../services/transaction_service.dart';
import '../services/transfer_service.dart';
import '../services/user_service.dart';
import '../widgets/amount_input.dart';
import '../widgets/banking_panel.dart';
import '../widgets/payment_warning_dialog.dart';
import 'support_screen.dart';
import 'auth/demo_session.dart';
import 'banking_operation_form.dart';
import 'transfer_success_screen.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key, this.onHome});
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final userId = context.watch<UserService>().currentUser?.id;
    final saved = context
        .watch<TransferService>()
        .recipients
        .where((recipient) =>
            recipient.userId == userId &&
            [11, 16].contains(
                recipient.accountNumber.replaceAll(RegExp(r'\D'), '').length))
        .toList()
      ..sort((a, b) => (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0));
    return Scaffold(
      appBar: AppBar(title: Text(uiText('Переводы'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BankingHeading(uiText('Частые')),
          SizedBox(
            height: 86,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final item in saved)
                  _frequent(
                      context,
                      item.name,
                      Icons.person_rounded,
                      () => _openForm(
                          context,
                          item.accountNumber
                                      .replaceAll(RegExp(r'\D'), '')
                                      .length ==
                                  16
                              ? 'card'
                              : 'phone',
                          item.accountNumber)),
                _frequent(
                    context,
                    uiText('По телефону'),
                    Icons.phone_iphone_rounded,
                    () => _openForm(context, 'phone')),
                _frequent(
                    context,
                    uiText('На карту'),
                    Icons.credit_card_rounded,
                    () => _openForm(context, 'card')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          BankingPanel(
            padding: 12,
            child: Column(
              children: [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: BankingHeading(uiText('Все переводы'))),
                _item(context, Icons.compare_arrows_rounded,
                    'Между своими счетами',
                    type: 'own'),
                _item(context, Icons.phone_iphone_outlined, 'Клиенту Veridian',
                    subtitle: uiText('По номеру телефона'), type: 'phone'),
                _item(context, Icons.credit_card_outlined,
                    'В другие банки Казахстана',
                    subtitle: uiText('По номеру карты'), type: 'card'),
                _item(context, Icons.language_outlined,
                    'Международные денежные переводы',
                    type: 'international'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BankingHeading(uiText('Дополнительно')),
          BankingPanel(
            padding: 0,
            child: Column(children: [
              ListTile(
                leading: const BankingIcon(Icons.headset_mic_rounded),
                title: Text(uiText('Связь с банком')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => isBankingDemo(context)
                    ? bankingNotice(
                        context,
                        uiText(
                            'В полной версии здесь открывается чат Veridian.'))
                    : openBankingScreen<void>(context, const SupportScreen()),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _frequent(BuildContext context, String title, IconData icon,
          VoidCallback action) =>
      SizedBox(
        width: 84,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action,
          child: Column(children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );

  Widget _item(BuildContext context, IconData icon, String title,
          {String? subtitle, required String type}) =>
      ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: SizedBox(
            width: 35,
            child: Icon(icon,
                size: 23, color: Theme.of(context).colorScheme.primary)),
        title: Text(uiText(title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          HapticFeedback.selectionClick();
          if (type == 'own' || type == 'international') {
            openBankingScreen<void>(
                context,
                BankingOperationForm(
                  operation: type == 'own'
                      ? BankingOperation.ownTransfer
                      : BankingOperation.international,
                  title: title,
                ));
          } else {
            _openForm(context, type);
          }
        },
      );

  Future<void> _openForm(BuildContext context, String type,
      [String? destination]) async {
    final confirmation = await showModalBottomSheet<
        ({double amount, String recipient, String currency})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      isDismissible: false,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 24, 16, MediaQuery.viewInsetsOf(sheet).bottom + 24),
        child: _TransferForm(type: type, destination: destination),
      ),
    );
    if (confirmation == null || !context.mounted) return;
    final done = await openBankingScreen<bool>(
        context,
        TransferSuccessScreen(
          amount: confirmation.amount,
          recipientName: confirmation.recipient,
          currency: confirmation.currency,
          homeActionAvailable: onHome != null,
        ));
    if (done == true && context.mounted) onHome?.call();
  }
}

class _TransferForm extends StatefulWidget {
  final String type;
  final String? destination;
  const _TransferForm({required this.type, this.destination});

  @override
  State<_TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<_TransferForm> {
  final _amountController = TextEditingController();
  final _dataController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedAccountId;

  String? _recipientName;
  bool _isChecking = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final destination = widget.destination;
    final formatter =
        widget.type == 'phone' ? PhoneInputFormatter() : CardInputFormatter();
    if (destination != null) {
      _dataController.value = formatter.formatEditUpdate(
          TextEditingValue.empty, TextEditingValue(text: destination));
    } else if (widget.type == 'phone') {
      _dataController.text = '+7 (';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dataController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final userId = context.watch<UserService>().currentUser?.id;
    final accounts = context
        .watch<AccountService>()
        .accounts
        .where((account) => account.userId == userId && account.isActive);
    final theme = Theme.of(context);
    // Цвет заливки полей ввода
    final inputFillColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey[50];

    // Фиксированный зеленый цвет для элементов акцента
    const brandColor = Color(0xFF10B981);

    String title = "";
    String hint = "";
    IconData icon = Icons.edit_rounded;
    List<TextInputFormatter> formatters = [];

    switch (widget.type) {
      case 'phone':
        title = uiText('По номеру телефона');
        hint = "+7 (777) 000-00-00";
        icon = Icons.phone_android_rounded;
        formatters = [PhoneInputFormatter()];
        break;
      case 'card':
        title = uiText('На карту');
        hint = "0000 0000 0000 0000";
        icon = Icons.credit_card_rounded;
        formatters = [CardInputFormatter()];
        break;
    }

    return PopScope(
      canPop: !_isSending,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                IconButton(
                  tooltip: uiText('Закрыть'),
                  onPressed: _isSending ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              isExpanded: true,
              dropdownColor: theme.colorScheme.surface,
              decoration: InputDecoration(
                labelText: uiText('Списать с'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                filled: true,
                fillColor: inputFillColor,
              ),
              items: accounts
                  .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Text(
                          "${isBankingDemo(context) ? uiText(a.accountName) : a.accountName} (${a.balance.toStringAsFixed(0)} ₸)",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dataController,
                    keyboardType: TextInputType.number,
                    inputFormatters: formatters,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: widget.type == 'phone'
                          ? uiText('Телефон')
                          : uiText('Номер карты'),
                      hintText: hint,
                      // Исправлено: используем brandColor
                      prefixIcon: Icon(icon, color: brandColor),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      filled: true,
                      fillColor: inputFillColor,
                    ),
                    onChanged: (_) => setState(() => _recipientName = null),
                  ),
                ),
                if (widget.type == 'phone') ...[
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed:
                        _isChecking || _isSending ? null : _checkRecipient,
                    style: IconButton.styleFrom(
                        backgroundColor: brandColor, // Исправлен фон кнопки
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        minimumSize: const Size(56, 56)),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search_rounded),
                  )
                ]
              ],
            ),
            if (_recipientName != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(_recipientName!,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            AmountInput(controller: _amountController, currencySymbol: '₸'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: uiText('Сообщение получателю'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                filled: true,
                fillColor: inputFillColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending || _isChecking ? null : _handleTransfer,
                child: Text(_isSending
                    ? uiText('Выполняем перевод…')
                    : uiText('Перевести')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _checkRecipient() async {
    if (_isChecking) return null;
    final phone = _dataController.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length != 11) {
      _feedback(uiText('Введите полный номер телефона'));
      return null;
    }
    setState(() => _isChecking = true);
    final user = isBankingDemo(context)
        ? {'firstName': uiText('Демо'), 'surname': uiText('Получатель')}
        : await context.read<TransferService>().searchUserByPhone(phone);
    if (!mounted) return null;
    final unchanged = _dataController.text.trim() == phone;
    final name =
        user == null ? null : "${user['firstName']} ${user['surname']}";
    setState(() {
      _isChecking = false;
      if (unchanged) _recipientName = name;
    });
    if (unchanged && name == null) _feedback(uiText('Пользователь не найден'));
    return unchanged ? name : null;
  }

  void _feedback(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _handleTransfer() async {
    if (_isSending || _isChecking) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) {
      _feedback(uiText('Введите корректную сумму'));
      return;
    }
    final userService = context.read<UserService>();
    final userId = userService.currentUser?.id;
    if (userId == null) return;
    final accounts = context.read<AccountService>();
    final messages = context.read<PaymentService>();
    final accountId = _selectedAccountId;
    final source = accounts.accounts
        .where((a) => a.id == accountId && a.userId == userId && a.isActive)
        .firstOrNull;
    if (source == null) {
      _feedback(uiText('Выберите счёт списания'));
      return;
    }
    final input = _dataController.text.trim();
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final byPhone = widget.type == 'phone';
    if (!byPhone && digits.length != 16) {
      _feedback(uiText('Введите полный номер карты'));
      return;
    }

    final demo = context.read<DemoAccounts?>();
    if (demo != null) {
      if (byPhone && digits.length != 11) {
        _feedback(uiText('Введите полный номер телефона'));
        return;
      }
      final recipient = byPhone
          ? uiText('Демо-получатель')
          : uiText('Карта •••• {0}', digits.substring(12));
      if (!demo.apply(context, source.id, -amount,
          description: recipient, category: 'Transfer')) {
        _feedback(uiText('Проверьте остаток на счёте.'));
        return;
      }
      Navigator.of(context).pop(
          (amount: amount, recipient: recipient, currency: source.currency));
      return;
    }

    setState(() => _isSending = true);
    final service = context.read<TransferService>();
    final history = context.read<TransactionService>();
    final note = _notesController.text.trim();

    try {
      final recipient = byPhone
          ? _recipientName ?? await _checkRecipient()
          : uiText('Карта •••• {0}', digits.substring(12));
      if (!mounted ||
          recipient == null ||
          input != _dataController.text.trim() ||
          userService.currentUser?.id != userId) {
        return;
      }
      final amountText = _amountController.text;
      final confirmed = await confirmPayment(context,
          kind: 'transfer', amount: amount, accountId: source.id);
      if (!mounted ||
          !confirmed ||
          input != _dataController.text.trim() ||
          amountText != _amountController.text ||
          userService.currentUser?.id != userId) {
        return;
      }
      final success = byPhone
          ? await service.performPhoneTransfer(
              sourceAccountId: source.id,
              phoneNumber: input,
              amount: amount,
              description: note)
          : await service.performCardTransfer(
              sourceAccountId: source.id,
              targetCardNumber: digits,
              amount: amount,
              description: note);
      if (!success) {
        if (mounted) _feedback(uiText('Ошибка перевода'));
        return;
      }
      if (userService.currentUser?.id != userId) return;
      final now = DateTime.now();
      final refresh =
          Future.wait([accounts.loadAccounts(userId), messages.loadPayments()]);
      final saved = await history.addTransaction(Transaction(
        id: const Uuid().v4(),
        userId: userId,
        accountId: source.id,
        type: 'debit',
        category: 'Transfer',
        amount: amount,
        currency: source.currency,
        recipient: recipient,
        description: note.isEmpty ? null : note,
        status: 'completed',
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      ));
      await refresh;
      if (!mounted || userService.currentUser?.id != userId) return;
      if (!saved) {
        _feedback(uiText(
            'Перевод выполнен. Не удалось сохранить операцию на устройстве.'));
      }
      Navigator.of(context).pop(
          (amount: amount, recipient: recipient, currency: source.currency));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class CardInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 16) text = text.substring(0, 16);

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
