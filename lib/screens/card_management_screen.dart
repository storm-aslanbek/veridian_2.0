import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import '../widgets/bank_card_details.dart';
import 'package:provider/provider.dart';
import 'package:veridian/providers/localization_provider.dart';
import 'package:veridian/services/card_service.dart';
import 'package:veridian/theme.dart';
import 'package:veridian/widgets/action_button.dart';
import 'package:veridian/widgets/bank_card_widget.dart';

class CardManagementScreen extends StatelessWidget {
  const CardManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardService = context.watch<CardService>();
    final localization = context.watch<LocalizationProvider>();
    final cards = cardService.cards;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          uiText('Мои карты'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: cards.isEmpty
            ? Center(
                child: Text(
                  localization.translate('no_cards'),
                  style: context.textStyles.bodyLarge?.withColor(
                    theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.builder(
                padding: AppSpacing.paddingLg,
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        BankCardWidget(
                          card: card,
                          onTap: () => showBankCardDetails(context, card),
                        ),
                        const SizedBox(height: 16),
                        // ИСПРАВЛЕНИЕ: Используем Column вместо Row, чтобы текст влезал
                        Column(
                          children: [
                            ActionButton(
                              label: card.isBlocked
                                  ? localization.translate('unblock')
                                  : localization.translate('block'),
                              onPressed: () => _toggleCardBlock(
                                  context, card.id, localization),
                              icon:
                                  card.isBlocked ? Icons.lock_open : Icons.lock,
                              isPrimary: false,
                              isFullWidth: true,
                            ),
                            const SizedBox(height: 12), // Отступ между кнопками
                            ActionButton(
                              label: localization.translate('settings'),
                              onPressed: () => _showCardSettings(context, card),
                              icon: Icons.settings,
                              isPrimary: false,
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _toggleCardBlock(
      BuildContext context, String cardId, LocalizationProvider localization) {
    context.read<CardService>().toggleCardBlock(cardId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localization.translate('cards'))),
    );
  }

  void _showCardSettings(BuildContext context, dynamic card) {
    final theme = Theme.of(context);
    final limitController =
        TextEditingController(text: card.spendingLimit.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              uiText('Настройки карты'),
              style: context.textStyles.titleLarge?.bold
                  .withColor(theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            Text(
              uiText('Лимит расходов'),
              style: context.textStyles.titleMedium?.semiBold
                  .withColor(theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                prefixText: '\$ ',
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ActionButton(
              label: uiText('Изменить лимит'),
              onPressed: () {
                final newLimit = double.tryParse(limitController.text);
                if (newLimit != null) {
                  context
                      .read<CardService>()
                      .updateSpendingLimit(card.id, newLimit);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(uiText('Лимит расходов обновлён'))),
                  );
                }
              },
              icon: Icons.check,
              isFullWidth: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
