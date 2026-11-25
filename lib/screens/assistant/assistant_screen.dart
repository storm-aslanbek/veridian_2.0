import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/assistant.dart';
import '../../services/assistant_service.dart';
import '../../services/ui_strings.dart';
import '../../widgets/ai/ai_effects.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/banking_panel.dart';
import 'assistant_chat_screen.dart';
import 'assistant_loading.dart';
import 'assistant_settings_screen.dart';
import 'assistant_summary_view.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _salaryController = TextEditingController();
  bool _busy = false;
  bool _analyzing = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await action();
    } catch (e) {
      debugPrint('Assistant error: $e');
      _failed = true;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _loadProfile() =>
      _run(context.read<AssistantService>().loadProfile);

  Future<void> _saveSalary() async {
    final salary = parseAmount(_salaryController.text);
    if (salary == null || salary <= 0) {
      bankingNotice(context, uiText('Введите корректную сумму'));
      return;
    }
    final service = context.read<AssistantService>();
    await _run(() => service.saveProfile(AssistantProfile(salary: salary)));
  }

  Future<void> _analyze() async {
    final service = context.read<AssistantService>();
    setState(() => _analyzing = true);
    await _run(() => Future.wait([
          service.analyze(),
          Future<void>.delayed(const Duration(milliseconds: 1800)),
        ]));
    if (mounted) setState(() => _analyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AssistantService>();
    final hasSalary = service.profile?.salary != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(uiText('Финансовый аналитик')),
        actions: [
          if (hasSalary)
            IconButton(
              tooltip: uiText('Настройки аналитика'),
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => openBankingScreen<void>(
                  context, const AssistantSettingsScreen()),
            ),
        ],
      ),
      floatingActionButton: hasSalary
          ? FloatingActionButton.extended(
              onPressed: () =>
                  openBankingScreen<void>(context, const AssistantChatScreen()),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(uiText('Спросить ИИ')),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                uiText('Не удалось связаться с сервером. Попробуйте ещё раз.'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_busy && !_analyzing) const LinearProgressIndicator(),
          ..._content(service),
        ],
      ),
    );
  }

  List<Widget> _content(AssistantService service) {
    final profile = service.profile;
    if (profile == null) {
      return [
        if (!_busy)
          FilledButton(
              onPressed: _loadProfile, child: Text(uiText('Повторить'))),
      ];
    }
    if (profile.salary == null) return [_salaryForm()];

    if (_analyzing) return [const AssistantLoading()];

    final summary = service.summary;
    if (summary == null) return [_intro()];
    return [
      AssistantSummaryView(summary: summary),
      OutlinedButton.icon(
        onPressed: _busy ? null : _analyze,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(uiText('Обновить')),
      ),
    ];
  }

  Widget _intro() => FadeSlideIn(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const AiOrb(size: 88),
            const SizedBox(height: 24),
            Text(uiText('Разберу ваши расходы за месяц'),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(uiText('Категории, подписки, лимиты и прогноз остатка.'),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            DecoratedBox(
              decoration: BoxDecoration(
                  gradient: aiGradient,
                  borderRadius: BorderRadius.circular(30)),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: _busy ? null : _analyze,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(uiText('Анализировать')),
              ),
            ),
          ],
        ),
      );

  Widget _salaryForm() => BankingPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BankingHeading(uiText('Ваша зарплата в месяц')),
            Text(uiText('На её основе аналитик будет делать расчёты.')),
            const SizedBox(height: 12),
            AmountField(controller: _salaryController, label: uiText('Сумма')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _saveSalary,
              child: Text(uiText('Сохранить')),
            ),
          ],
        ),
      );
}
