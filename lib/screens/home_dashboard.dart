import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bank_account.dart';
import '../models/card.dart';
import '../providers/localization_provider.dart';
import '../services/account_service.dart';
import '../services/card_service.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';
import '../widgets/balance_card.dart';
import '../theme.dart';
import '../widgets/bank_card_details.dart';
import '../widgets/banking_panel.dart';
import 'analytics_screen.dart';
import 'auth/demo_session.dart';
import 'banking_operation_form.dart';
import 'business_check_screen.dart';
import 'loan_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'qr_screen.dart';
import 'services_screen.dart';
import 'support_screen.dart';
import 'transfer_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final _cards = PageController(viewportFraction: .90);
  bool _showBalance = true;
  int _page = 0;
  bool _freezing = false;
  static const _languages = [
    (AppLanguage.en, 'EN'),
    (AppLanguage.kk, 'ҚАЗ'),
    (AppLanguage.ru, 'РУС')
  ];

  @override
  void dispose() {
    _cards.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final demo = isBankingDemo(context);
    final language = context.watch<LocalizationProvider>();
    final accounts = context
        .watch<AccountService>()
        .accounts
        .where((a) => a.userId == user.id);
    final current = [
      ...accounts.where((a) => !_isDeposit(a)),
      ...accounts.where(_isDeposit)
    ];
    final cards = context
        .watch<CardService>()
        .cards
        .where((card) => card.userId == user.id);
    final selected = _page < current.length ? current[_page] : null;
    final card =
        cards.where((card) => card.accountId == selected?.id).firstOrNull;
    final pages = (current.isEmpty ? 1 : current.length) + 1;
    final fullName = user.firstName.isEmpty
        ? 'Veridian'
        : demo
            ? uiText(user.firstName)
            : user.firstName;
    final greeting = switch (language.currentLanguage) {
      AppLanguage.ru => 'Здравствуйте, $fullName',
      AppLanguage.en => 'Hello, $fullName',
      AppLanguage.kk => 'Сәлеметсіз бе, $fullName',
    };
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 55,
        titleSpacing: 16,
        title: const Text('Veridian',
            style: TextStyle(
                fontWeight: FontWeight.w900, letterSpacing: -.9, fontSize: 23)),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 350)
            for (final (choice, label) in _languages)
              TextButton(
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    minimumSize: const Size(32, 40),
                    foregroundColor: language.currentLanguage == choice
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                    backgroundColor: language.currentLanguage == choice
                        ? colors.primaryContainer
                        : Colors.transparent,
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800)),
                onPressed: () => language.setLanguage(choice),
                child: Text(label),
              )
          else
            PopupMenuButton<AppLanguage>(
              tooltip: uiText('Язык'),
              initialValue: language.currentLanguage,
              onSelected: language.setLanguage,
              itemBuilder: (_) => [
                for (final (value, label) in _languages)
                  PopupMenuItem(value: value, child: Text(label))
              ],
              icon: const Icon(Icons.translate_rounded),
            ),
          const BankingThemeToggle(),
          IconButton(
            tooltip: uiText('Уведомления'),
            onPressed: () =>
                openBankingScreen<void>(context, const MessagesScreen()),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AccountService>().loadAccounts(user.id),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () =>
                  openBankingScreen<void>(context, const ProfileScreen()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(fullName.characters.first.toUpperCase()),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text(greeting,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16))),
                  if (demo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(uiText('ДЕМО'),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: colors.onPrimaryContainer)),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 5),
            Column(children: [
              SizedBox(
                height: 212,
                child: PageView.builder(
                  controller: _cards,
                  padEnds: false,
                  itemCount: pages,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (_, index) {
                    final account =
                        index < current.length ? current[index] : null;
                    final linked = cards
                        .where((card) =>
                            account != null && card.accountId == account.id)
                        .firstOrNull;
                    final digits =
                        (linked?.cardNumber ?? account?.accountNumber ?? '')
                            .replaceAll(RegExp(r'\D'), '');
                    final tail = digits.length < 4
                        ? ''
                        : digits.substring(digits.length - 4);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 4, 10, 8),
                      child: index == pages - 1
                          ? NewBalanceCard(
                              onTap: () => bankingNotice(
                                  context,
                                  uiText(
                                      'Выпуск новой карты появится после подключения банковского сервиса.')))
                          : BalanceCard(
                              balance: !_showBalance
                                  ? '•••••• ₸'
                                  : account == null
                                      ? '— ₸'
                                      : bankingAmount(
                                          account.balance, account.currency),
                              number: tail.isEmpty ? '••••' : '•••• $tail',
                              caption: (demo && account != null
                                      ? uiText(account.accountName)
                                      : account?.accountName) ??
                                  uiText('Ваш банковский счёт'),
                              expiry: linked?.expiryDate,
                              visa: linked?.cardNumber.startsWith('4') ?? false,
                              onTap: account == null
                                  ? null
                                  : () => _details(account, linked),
                            ),
                    );
                  },
                ),
              ),
              Row(children: [
                Expanded(
                    child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact),
                    onPressed: () =>
                        setState(() => _showBalance = !_showBalance),
                    icon: Icon(
                        _showBalance
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 16),
                    label: Text(
                        _showBalance
                            ? uiText('Скрыть баланс')
                            : uiText('Показать баланс'),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                )),
                IconButton(
                  tooltip: uiText('Предыдущая карта'),
                  visualDensity: VisualDensity.compact,
                  onPressed: _page > 0
                      ? () => _cards.previousPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 21),
                ),
                Text('${(_page + 1).clamp(1, pages)} / $pages',
                    style: Theme.of(context).textTheme.labelSmall),
                IconButton(
                  tooltip: uiText('Следующая карта'),
                  visualDensity: VisualDensity.compact,
                  onPressed: _page < pages - 1
                      ? () => _cards.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 21),
                ),
              ]),
            ]),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: _QuickAction(
                      uiText('Перевод'),
                      Icons.swap_horiz_rounded,
                      () => openBankingScreen<void>(
                          context, const TransferScreen()))),
              Expanded(
                  child: _QuickAction(
                      uiText('Пополнить'),
                      Icons.add_rounded,
                      () => openBankingScreen<void>(
                          context,
                          BankingOperationForm(
                              operation: BankingOperation.topUp,
                              title: 'Пополнить',
                              initialAccountId: selected?.id)))),
              Expanded(
                  child: _QuickAction(
                      uiText('Реквизиты'),
                      Icons.credit_card_outlined,
                      () => _cardDetails(selected, card, cards))),
              Expanded(
                  child: _QuickAction(
                      card?.isBlocked == true
                          ? uiText('Разморозить')
                          : uiText('Заморозить'),
                      Icons.ac_unit_rounded,
                      () => _freeze(card, cards))),
            ]),
            const SizedBox(height: 12),
            _daily(user.id, demo, selected, _showBalance),
            const SizedBox(height: 12),
            _promotions(demo),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: _bento(
                      uiText('Моя аналитика'),
                      uiText('Доходы и расходы'),
                      Icons.donut_large_rounded,
                      BankingTone.blue,
                      () => openBankingScreen<void>(
                          context, AnalyticsScreen(hideBalance: !_showBalance)),
                      chart: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _bento(
                      uiText('Кэшбэк и скидки'),
                      uiText('Предложения Veridian'),
                      Icons.local_offer_rounded,
                      BankingTone.purple,
                      () => openBankingScreen<void>(
                          context, const ServicesScreen(initialCategory: 1)))),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _chip('QR', Icons.qr_code_rounded, const QrScanPage(), demo),
                _chip(uiText('Чат AI'), Icons.auto_awesome_rounded,
                    const SupportScreen(), demo),
                _chip(uiText('Госуслуги'), Icons.account_balance_rounded,
                    const ServicesScreen(initialCategory: 3), false),
                _chip(uiText('Бизнес'), Icons.fact_check_rounded,
                    const BusinessCheckScreen(), demo),
              ]),
            ),
            const SizedBox(height: 18),
            BankingPanel(
              padding: 12,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: BankingHeading(uiText('Вам может быть интересно')),
                    ),
                    for (final (title, icon, page) in [
                      (
                        uiText('Взять кредит'),
                        Icons.payments_outlined,
                        const LoanScreen()
                      ),
                      (
                        uiText('Открыть депозитный счёт'),
                        Icons.savings_outlined,
                        null
                      ),
                      (
                        uiText('Брокерский счёт'),
                        Icons.bar_chart_rounded,
                        null
                      ),
                      (
                        uiText('Проверка бизнеса'),
                        Icons.fact_check_outlined,
                        const BusinessCheckScreen()
                      ),
                    ])
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        leading: BankingIcon(icon, size: 40),
                        title: Text(title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        trailing:
                            const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () {
                          if (page == null) {
                            bankingNotice(
                                context,
                                uiText(
                                    'Оформление появится после подключения банковского сервиса.'));
                          } else {
                            _openFeature(page, demo);
                          }
                        },
                      ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDeposit(BankAccount account) => ['deposit', 'saving', 'депозит']
      .any(account.accountType.toLowerCase().contains);

  void _details(BankAccount? account, BankCard? card) {
    if (card != null) {
      showBankCardDetails(context, card);
    } else if (account != null) {
      bankingNotice(
          context, '${account.accountName}\n${account.accountNumber}');
    } else {
      bankingNotice(context, uiText('Выберите счёт или карту в карусели.'));
    }
  }

  Future<BankCard?> _chooseCard(Iterable<BankCard> cards) {
    return showModalBottomSheet<BankCard>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            BankingHeading(uiText('Выберите карту')),
            for (final card in cards)
              ListTile(
                leading: const BankingIcon(Icons.credit_card_rounded),
                title: Text(card.maskedCardNumber),
                subtitle: Text(card.accountId.startsWith('sample-account-id')
                    ? uiText('Демо-карта')
                    : card.isBlocked
                        ? uiText('Заморожена')
                        : cardTypeLabel(card.cardType)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheet, card),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cardDetails(
      BankAccount? account, BankCard? linked, Iterable<BankCard> cards) async {
    if (linked != null || cards.isEmpty) {
      _details(account, linked);
      return;
    }
    final choice = await _chooseCard(cards);
    if (mounted && choice != null) showBankCardDetails(context, choice);
  }

  Future<void> _freeze(BankCard? linked, Iterable<BankCard> cards) async {
    if (_freezing) return;
    if (linked == null && cards.isEmpty) {
      bankingNotice(
          context, uiText('Добавьте карту, чтобы управлять её статусом.'));
      return;
    }
    _freezing = true;
    try {
      final card = linked ?? await _chooseCard(cards);
      if (!mounted || card == null) return;
      final demo = isBankingDemo(context);
      final saved = await context.read<CardService>().toggleCardBlock(card.id);
      if (!mounted) return;
      final state = card.isBlocked
          ? uiText('Карта разморожена')
          : uiText('Карта заморожена');
      final message = saved
          ? demo
              ? state
              : uiText('{0} на этом устройстве', state)
          : uiText('Не удалось изменить статус карты');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _freezing = false;
    }
  }

  Widget _daily(String userId, bool demo, BankAccount? account, bool show) {
    final now = DateTime.now();
    final key = 'ui_daily_limit_$userId';
    final limit = demo ? 160000.0 : LocalStorageService.getDouble(key);
    final spent = context
        .watch<TransactionService>()
        .transactions
        .where(
          (item) =>
              item.userId == userId &&
              item.accountId == account?.id &&
              item.currency == 'KZT' &&
              item.type == 'debit' &&
              item.status == 'completed' &&
              DateUtils.isSameDay(item.transactionDate.toLocal(), now),
        )
        .fold<double>(0, (sum, item) => sum + item.amount.abs());
    final remaining = ((limit ?? 0) - spent).clamp(0.0, limit ?? 0);
    return BankingPanel(
        padding: 0,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          leading: SizedBox.square(
              dimension: 46,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: show && limit != null && limit > 0
                            ? remaining / limit
                            : 0,
                        strokeWidth: 4,
                        color: const Color(0xFF10B981),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer)),
                const Icon(Icons.bar_chart_rounded,
                    size: 24, color: Color(0xFF10B981)),
              ])),
          subtitle: Text(uiText('Можно потратить сегодня'),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          title: Text(
              !show
                  ? '•••••• ₸'
                  : limit == null
                      ? uiText('Задать дневной лимит')
                      : bankingAmount(remaining),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          trailing: Icon(
              demo ? Icons.info_outline_rounded : Icons.chevron_right_rounded,
              size: 19),
          onTap: demo
              ? () => bankingNotice(
                  context,
                  uiText(
                      'Демо-лимит учитывает сегодняшние расходы выбранного счёта.'))
              : () => _editLimit(key, limit),
        ));
  }

  Future<void> _editLimit(String key, double? initial) async {
    double? value = initial;
    final chosen = await showDialog<double>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: Text(uiText('Лимит для планирования')),
              content: TextFormField(
                initialValue: initial?.toStringAsFixed(0),
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: uiText('Дневной лимит в тенге')),
                onChanged: (raw) =>
                    value = double.tryParse(raw.replaceAll(',', '.')),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog),
                    child: Text(uiText('Отмена'))),
                FilledButton(
                    onPressed: () {
                      final amount = value;
                      if (amount != null && amount.isFinite && amount > 0)
                        Navigator.pop(dialog, amount);
                    },
                    child: Text(uiText('Сохранить'))),
              ],
            ));
    if (chosen == null || !mounted) return;
    final saved = await LocalStorageService.saveDouble(key, chosen);
    if (mounted && saved) setState(() {});
  }

  Widget _promotions(bool demo) {
    final entries = [
      (
        uiText('Новые карты в USD'),
        Icons.credit_card_rounded,
        const Color(0xFF006552),
        const Color(0xFF1A9B78),
        () => bankingNotice(context,
            uiText('Оформление карт в USD появится после подключения выпуска.'))
      ),
      (
        uiText('AI-ассистент Veridian'),
        Icons.auto_awesome_rounded,
        const Color(0xFF104C67),
        const Color(0xFF2B7E91),
        () => _openFeature(const SupportScreen(), demo)
      ),
      (
        uiText('Перевод за рубеж'),
        Icons.public_rounded,
        const Color(0xFF403474),
        const Color(0xFF7158AE),
        () => openBankingScreen<void>(
            context,
            BankingOperationForm(
                operation: BankingOperation.international,
                title: 'Международные переводы'))
      ),
    ];
    return Row(spacing: 7, children: [
      for (final (title, icon, start, end, tap) in entries)
        Expanded(
          child: AspectRatio(
              aspectRatio: 1,
              child: Material(
                color: start,
                borderRadius: BorderRadius.circular(15),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [start, end],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      tap();
                    },
                    child: Stack(children: [
                      Positioned(
                          right: -8,
                          bottom: -12,
                          child: Transform.rotate(
                              angle: -.24,
                              child: Icon(icon,
                                  color: const Color(0x57FFFFFF), size: 78))),
                      Positioned.fill(
                          child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: Text(title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      height: 1.08,
                                      fontWeight: FontWeight.w800)))),
                    ]),
                  ),
                ),
              )),
        ),
    ]);
  }

  void _openFeature(Widget page, bool demo) {
    if (demo) {
      bankingNotice(
          context, uiText('Этот сервис открывается после входа в аккаунт.'));
    } else {
      openBankingScreen<void>(context, page);
    }
  }

  Widget _chip(String label, IconData icon, Widget page, bool demo) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ActionChip(
            avatar: Icon(icon, size: 17),
            label: Text(label),
            onPressed: () => _openFeature(page, demo)),
      );

  Widget _bento(String title, String subtitle, IconData icon, BankingTone tone,
          VoidCallback tap,
          {bool chart = false}) =>
      BankingPanel(
          padding: 0,
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BankingIcon(icon, tone: tone),
                      const SizedBox(height: 5),
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 7),
                      SizedBox(
                          height: 5,
                          child: chart
                              ? Row(children: [
                                  for (var i = 0; i < 4; i++)
                                    Expanded(
                                        flex: 4 - i,
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 3),
                                          decoration: BoxDecoration(
                                              color: analyticsColors[i],
                                              borderRadius:
                                                  BorderRadius.circular(3)),
                                        )),
                                ])
                              : const SizedBox.shrink()),
                    ])),
          ));
}

class _QuickAction extends StatefulWidget {
  const _QuickAction(this.label, this.icon, this.action);
  final String label;
  final IconData icon;
  final VoidCallback action;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: _pressed ? .92 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 110),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.action();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? VeridianColors.surfaceStrong
                    : const Color(0xFFE6F6F2),
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Theme.of(context).colorScheme.onPrimaryContainer,
                child: Icon(widget.icon, size: 28),
              ),
              const SizedBox(height: 5),
              Text(widget.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}
