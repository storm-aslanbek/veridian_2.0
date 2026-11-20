import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:veridian/providers/localization_provider.dart';
import 'package:veridian/services/loan_service.dart';
import 'package:veridian/theme.dart';
import 'package:veridian/widgets/action_button.dart';

class LoanScreen extends StatelessWidget {
  const LoanScreen({super.key, this.product});

  final String? product;

  @override
  Widget build(BuildContext context) {
    final loanService = context.watch<LoanService>();
    final localization = context.watch<LocalizationProvider>();
    final theme = Theme.of(context);
    final activeLoans = loanService.activeLoans;
    // Изменили символ валюты на Тенге
    final currencyFormat = NumberFormat.currency(
        symbol: '₸',
        decimalDigits: 0,
        locale: Localizations.localeOf(context).languageCode);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(product ?? localization.translate('loans'),
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        elevation: 0,
      ),
      body: SafeArea(
        child: activeLoans.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 80,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localization.translate('no_active_loans'),
                      style: context.textStyles.titleLarge?.semiBold
                          .withColor(theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localization.translate('apply_for_new_loan'),
                      style: context.textStyles.bodyMedium?.withColor(
                        theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: AppSpacing.paddingLg,
                itemCount: activeLoans.length,
                itemBuilder: (context, index) {
                  final loan = activeLoans[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: AppSpacing.paddingLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_balance,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      switch (loan.loanType) {
                                        'Personal Loan' =>
                                          uiText('Потребительский кредит'),
                                        'Auto Loan' => uiText('Автокредит'),
                                        _ => loan.loanType,
                                      },
                                      style: context
                                          .textStyles.titleMedium?.bold
                                          .withColor(
                                              theme.colorScheme.onSurface),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      loan.status == 'active'
                                          ? uiText('Активен')
                                          : loan.status,
                                      style: context.textStyles.labelSmall
                                          ?.withColor(
                                        theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(loan.principalAmount),
                                style: context.textStyles.titleMedium?.bold
                                    .withColor(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoColumn(
                                  context,
                                  localization.translate('monthly_payment'),
                                  currencyFormat.format(loan.monthlyPayment),
                                  theme,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoColumn(
                                  context,
                                  localization.translate('interest_rate'),
                                  '${loan.interestRate.toStringAsFixed(1)}%',
                                  theme,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoColumn(
                                  context,
                                  localization.translate('total_paid'),
                                  currencyFormat.format(loan.totalPaid),
                                  theme,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoColumn(
                                  context,
                                  localization.translate('remaining'),
                                  currencyFormat.format(loan.remainingAmount),
                                  theme,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            localization.translate('loan_progress'),
                            style: context.textStyles.labelSmall?.withColor(
                              theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: loan.progressPercentage / 100,
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${loan.progressPercentage.toStringAsFixed(1)}% ${localization.translate('loan_complete')}',
                            style: context.textStyles.labelSmall?.withColor(
                              theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (loan.nextPaymentDate != null)
                            Container(
                              padding: AppSpacing.paddingMd,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${localization.translate('next_payment')}: ${dateFormat.format(loan.nextPaymentDate!)}',
                                    style: context
                                        .textStyles.bodyMedium?.semiBold
                                        .withColor(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          ActionButton(
                            label: localization.translate('make_payment'),
                            onPressed: () => _makePayment(context, loan.id,
                                loan.monthlyPayment, localization),
                            icon: Icons.payment,
                            isFullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      // Кнопка создания нового кредита
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLoanDialog(context, localization),
        icon: const Icon(Icons.add),
        label: Text(localization.translate('new_loan')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildInfoColumn(
      BuildContext context, String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textStyles.labelSmall?.withColor(
            theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textStyles.bodyLarge?.semiBold
              .withColor(theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  void _makePayment(BuildContext context, String loanId, double amount,
      LocalizationProvider localization) {
    context.read<LoanService>().makePayment(loanId, amount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(localization.translate('payment_success')),
          backgroundColor: const Color(0xFF10B981)),
    );
  }

  // === ЛОГИКА ЗАЯВКИ НА КРЕДИТ ===
  void _showApplyLoanDialog(
      BuildContext context, LocalizationProvider localization) {
    var rawAmount = '';
    var rawTerm = '12';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product == null
                  ? localization.translate('loan_application')
                  : uiText('Заявка · {0}', product),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(uiText('Демо-форма заявки. Отправка в банк пока недоступна.')),
            const SizedBox(height: 12),
            TextFormField(
              onChanged: (text) => rawAmount = text,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localization.translate('loan_amount'),
                suffixText: '₸',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            // Поле срока
            TextFormField(
              initialValue: rawTerm,
              onChanged: (text) => rawTerm = text,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localization.translate('loan_term'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            // Кнопка отправки
            ActionButton(
              label: uiText('Проверить заявку'),
              isFullWidth: true,
              onPressed: () {
                final amount = double.tryParse(rawAmount.replaceAll(',', '.'));
                final months = int.tryParse(rawTerm);

                final valid = amount != null &&
                    amount.isFinite &&
                    amount > 0 &&
                    months != null &&
                    months > 0;
                if (!valid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(uiText('Введите корректную сумму и срок.'))),
                  );
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(uiText(
                          'Данные проверены. Отправка заявки пока недоступна.'))),
                );
              },
            ),
          ],
        ),
      )),
    );
  }
}
