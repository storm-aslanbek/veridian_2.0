import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/assistant.dart';
import '../../models/payment.dart';
import '../../services/assistant_service.dart';
import '../../services/ui_strings.dart';
import '../../widgets/amount_field.dart';
import '../../widgets/banking_panel.dart';

class AssistantSettingsScreen extends StatefulWidget {
  const AssistantSettingsScreen({super.key});

  @override
  State<AssistantSettingsScreen> createState() =>
      _AssistantSettingsScreenState();
}

class _AssistantSettingsScreenState extends State<AssistantSettingsScreen> {
  static const _goalMonths = 36;

  final _salary = TextEditingController();
  final _goalAmount = TextEditingController();
  final _goalSaved = TextEditingController();
  final _limits = {
    for (final category in brandCategories) category: TextEditingController()
  };
  bool _alerts = false;
  String? _targetMonth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AssistantService>().profile!;
    _salary.text = _format(profile.salary);
    _alerts = profile.anomalyAlerts;
    for (final entry in _limits.entries) {
      entry.value.text = _format(profile.categoryLimits[entry.key]);
    }
    _goalAmount.text = _format(profile.goal?.amount);
    _goalSaved.text = _format(profile.goal?.savedAmount);
    _targetMonth = profile.goal?.targetMonth;
  }

  @override
  void dispose() {
    for (final controller in [
      _salary,
      _goalAmount,
      _goalSaved,
      ..._limits.values
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _format(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  List<String> get _monthOptions {
    final now = DateTime.now();
    final months = [
      for (var offset = 0; offset < _goalMonths; offset++)
        _monthKey(DateTime(now.year, now.month + offset))
    ];
    final saved = _targetMonth;
    return [if (saved != null && !months.contains(saved)) saved, ...months];
  }

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  AssistantProfile? _readForm() {
    final salary = parseAmount(_salary.text);
    if (salary == null || salary <= 0) return null;

    final limits = <String, double>{};
    for (final entry in _limits.entries) {
      if (entry.value.text.isEmpty) continue;
      final limit = parseAmount(entry.value.text);
      if (limit == null || limit <= 0) return null;
      limits[entry.key] = limit;
    }

    SavingsGoal? goal;
    if (_goalAmount.text.isNotEmpty) {
      final amount = parseAmount(_goalAmount.text);
      final saved =
          _goalSaved.text.isEmpty ? 0.0 : parseAmount(_goalSaved.text);
      final month = _targetMonth;
      if (amount == null || amount <= 0 || saved == null || month == null) {
        return null;
      }
      goal =
          SavingsGoal(amount: amount, savedAmount: saved, targetMonth: month);
    }

    return AssistantProfile(
        salary: salary,
        anomalyAlerts: _alerts,
        categoryLimits: limits,
        goal: goal);
  }

  Future<void> _save() async {
    final profile = _readForm();
    if (profile == null) {
      bankingNotice(context, uiText('Проверьте заполнение полей.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AssistantService>().saveProfile(profile);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Assistant settings error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      bankingNotice(context,
          uiText('Не удалось связаться с сервером. Попробуйте ещё раз.'));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(uiText('Настройки аналитика'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AmountField(
                controller: _salary, label: uiText('Ваша зарплата в месяц')),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(uiText('Предупреждать о крупных операциях')),
              subtitle: Text(uiText(
                  'Аналитик учтёт зарплату, остаток на счёте и ваши обычные суммы.')),
              value: _alerts,
              onChanged: (value) => setState(() => _alerts = value),
            ),
            const SizedBox(height: 12),
            BankingHeading(uiText('Лимиты')),
            Text(uiText('Пустое поле означает, что лимита нет.')),
            for (final entry in _limits.entries)
              AmountField(
                  controller: entry.value,
                  label: brandCategoryLabel(entry.key)),
            const SizedBox(height: 20),
            BankingHeading(uiText('Цель накопления')),
            AmountField(controller: _goalAmount, label: uiText('Сумма цели')),
            AmountField(controller: _goalSaved, label: uiText('Накоплено')),
            DropdownButtonFormField<String>(
              initialValue: _targetMonth,
              decoration: InputDecoration(labelText: uiText('К какому месяцу')),
              items: [
                for (final month in _monthOptions)
                  DropdownMenuItem(
                      value: month,
                      child: Text(month.split('-').reversed.join('.'))),
              ],
              onChanged: (value) => setState(() => _targetMonth = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(uiText('Сохранить')),
            ),
          ],
        ),
      );
}
