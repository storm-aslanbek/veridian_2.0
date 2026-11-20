import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

import '../widgets/banking_panel.dart';
import 'bill_payment_screen.dart';
import 'auth/demo_session.dart';
import 'business_check_screen.dart';
import 'card_management_screen.dart';
import 'career_screen.dart';
import 'faq_screen.dart';
import 'loan_screen.dart';
import 'map_screen.dart';
import 'mobile_payment_screen.dart';
import 'shopping_navigator_screen.dart';
import 'assau_screen.dart';
import 'support_screen.dart';
import 'transactions_screen.dart';
import 'transfer_screen.dart';

typedef _ServiceLink = ({IconData icon, String title, Widget? screen});

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.initialCategory});
  final int? initialCategory;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _city = 'Тараз';
  int? _selected;

  static const _groups = <(String, List<_ServiceLink>)>[
    (
      'Новое',
      [
        (
          icon: Icons.auto_awesome_rounded,
          title: 'AI-чат',
          screen: SupportScreen()
        ),
        (
          icon: Icons.fact_check_rounded,
          title: 'Проверка бизнеса',
          screen: BusinessCheckScreen()
        ),
        (
          icon: Icons.add_box_rounded,
          title: 'Assau Tender',
          screen: AssauTenderHelperScreen()
        ),
        (icon: Icons.work_rounded, title: 'Карьера', screen: CareerScreen()),
      ]
    ),
    (
      'Лайфстайл',
      [
        (
          icon: Icons.shopping_bag_rounded,
          title: 'Покупки',
          screen: ShoppingNavigatorScreen()
        ),
        (
          icon: Icons.local_offer_rounded,
          title: 'Кэшбэк и скидки',
          screen: null
        ),
        (icon: Icons.map_rounded, title: 'Карта', screen: MapPage()),
        (
          icon: Icons.confirmation_number_rounded,
          title: 'Билеты',
          screen: null
        ),
      ]
    ),
    (
      'Финансы',
      [
        (
          icon: Icons.credit_card_rounded,
          title: 'Карты',
          screen: CardManagementScreen()
        ),
        (
          icon: Icons.receipt_long_rounded,
          title: 'Кредиты',
          screen: LoanScreen()
        ),
        (
          icon: Icons.swap_horiz_rounded,
          title: 'Переводы',
          screen: TransferScreen()
        ),
        (
          icon: Icons.history_rounded,
          title: 'История',
          screen: TransactionsScreen()
        ),
      ]
    ),
    (
      'Госуслуги',
      [
        (icon: Icons.article_rounded, title: 'Документы', screen: null),
        (
          icon: Icons.fact_check_rounded,
          title: 'Проверка бизнеса',
          screen: BusinessCheckScreen()
        ),
        (
          icon: Icons.account_balance_rounded,
          title: 'Налоги и штрафы',
          screen: null
        ),
        (
          icon: Icons.health_and_safety_rounded,
          title: 'Статус ОСМС',
          screen: null
        ),
      ]
    ),
    (
      'Страхование',
      [
        (icon: Icons.directions_car_rounded, title: 'Авто', screen: null),
        (icon: Icons.flight_takeoff_rounded, title: 'Поездки', screen: null),
        (icon: Icons.home_rounded, title: 'Имущество', screen: null),
        (icon: Icons.shield_rounded, title: 'Полисы', screen: null),
      ]
    ),
    (
      'Другие сервисы',
      [
        (
          icon: Icons.qr_code_scanner_rounded,
          title: 'Мобильные платежи',
          screen: MobilePaymentScreen()
        ),
        (
          icon: Icons.payments_rounded,
          title: 'Счета',
          screen: BillPaymentScreen()
        ),
        (
          icon: Icons.headset_mic_rounded,
          title: 'Поддержка',
          screen: SupportScreen()
        ),
        (icon: Icons.help_rounded, title: 'Вопросы', screen: FaqScreen()),
      ]
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final groups = _selected == null ? _groups : [_groups[_selected!]];
    return Scaffold(
      appBar: AppBar(
        title: Text(uiText('Сервисы')),
        actions: [
          BankingCityPicker(
              city: _city, onChanged: (city) => setState(() => _city = city))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: const Color(0xFF18483F),
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF98F2CE), size: 32),
              title: Text(uiText('AI-помощник Veridian'),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              subtitle: Text(uiText('Задайте вопрос в чате'),
                  style: TextStyle(color: Color(0xFFD3F2E8))),
              trailing:
                  const Icon(Icons.arrow_outward_rounded, color: Colors.white),
              onTap: () => isBankingDemo(context)
                  ? bankingNotice(context,
                      uiText('В полной версии здесь открывается чат Veridian.'))
                  : openBankingScreen<void>(context, const SupportScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              for (final (index, group) in _groups.indexed)
                FilterChip(
                  label: Text(uiText(group.$1)),
                  selected: _selected == index,
                  showCheckmark: false,
                  onSelected: (value) =>
                      setState(() => _selected = value ? index : null),
                ),
            ],
          ),
          for (final (title, entries) in groups) ...[
            const SizedBox(height: 18),
            BankingHeading(uiText(title)),
            BankingPanel(
              padding: 8,
              child: LayoutBuilder(builder: (context, constraints) {
                const gap = 4.0;
                final columns = constraints.maxWidth < 320 ? 3 : 4;
                final width =
                    (constraints.maxWidth - (columns - 1) * gap) / columns;
                final style = _labelStyle(context);
                final scaledLine =
                    MediaQuery.textScalerOf(context).scale(style.fontSize!) *
                        style.height!;
                final labels = TextPainter(
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                );
                var labelHeight = scaledLine * 2;
                for (final entry in entries) {
                  labels.text =
                      TextSpan(text: uiText(entry.title), style: style);
                  labels.layout(
                      maxWidth: (width - 4).clamp(1, double.infinity));
                  if (labels.height > labelHeight) labelHeight = labels.height;
                }
                labels.dispose();

                return GridView.count(
                  primary: false,
                  crossAxisCount: columns,
                  childAspectRatio: width / (44 + 8 + 16 + labelHeight + 1),
                  crossAxisSpacing: gap,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final (index, entry) in entries.indexed)
                      _serviceTile(
                          context,
                          entry,
                          BankingTone
                              .values[index % BankingTone.values.length]),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  void _openService(BuildContext context, _ServiceLink entry) {
    final screen = entry.screen;
    if (screen == null) {
      bankingNotice(
          context,
          uiText('«{0}» появится в каталоге после подключения сервиса.',
              uiText(entry.title)));
    } else if (isBankingDemo(context) &&
        screen is! TransferScreen &&
        screen is! BillPaymentScreen &&
        screen is! TransactionsScreen &&
        screen is! CardManagementScreen &&
        screen is! FaqScreen) {
      bankingNotice(
          context,
          uiText(
              '«{0}» открывается после входа в аккаунт.', uiText(entry.title)));
    } else {
      openBankingScreen<void>(context, screen);
    }
  }

  TextStyle _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w600,
          );

  Widget _serviceTile(
      BuildContext context, _ServiceLink entry, BankingTone tone) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openService(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          children: [
            BankingIcon(entry.icon, tone: tone),
            const SizedBox(height: 8),
            Text(
              uiText(entry.title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: _labelStyle(context).copyWith(
                color: entry.screen == null
                    ? colors.onSurfaceVariant
                    : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
