import 'package:flutter/material.dart';
import '../services/ui_strings.dart';
import 'package:provider/provider.dart';
import 'package:veridian/providers/localization_provider.dart'; // Импорт провайдера
import 'package:veridian/theme.dart';
import 'package:veridian/screens/qr_screen.dart';

class MobilePaymentScreen extends StatelessWidget {
  const MobilePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем локализацию и тему
    final localization = context.watch<LocalizationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localization.translate('mobile_payment'),
          style: TextStyle(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildPaymentOption(
                context,
                icon: Icons.qr_code_scanner,
                title: localization.translate('scan_qr_code'),
                description: localization.translate('scan_qr_desc_action'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QrScanPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildPaymentOption(
                context,
                icon: Icons.nfc,
                title: localization.translate('nfc_payment'),
                description: localization.translate('nfc_desc'),
                onTap: () => _showNFCPayment(context, localization),
              ),
              const SizedBox(height: 32),
              Text(
                localization.translate('quick_payments'),
                style: context.textStyles.titleLarge?.semiBold
                    .withColor(theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    children: [
                      _buildQuickPaymentTile(
                        context,
                        icon: Icons.coffee,
                        name: uiText('Кофейня'),
                        amount: '550 ₸',
                        onTap: () {},
                      ),
                      Divider(
                          color: theme.colorScheme.outline.withOpacity(0.2)),
                      _buildQuickPaymentTile(
                        context,
                        icon: Icons.local_gas_station,
                        name: 'Helios',
                        amount: '4500 ₸',
                        onTap: () {},
                      ),
                      Divider(
                          color: theme.colorScheme.outline.withOpacity(0.2)),
                      _buildQuickPaymentTile(
                        context,
                        icon: Icons.restaurant,
                        name: 'KFC',
                        amount: '3200 ₸',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleMedium?.semiBold
                          .withColor(theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: context.textStyles.bodySmall?.withColor(
                        theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPaymentTile(
    BuildContext context, {
    required IconData icon,
    required String name,
    required String amount,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.verticalMd,
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: context.textStyles.bodyLarge?.semiBold
                      .withColor(theme.colorScheme.onSurface)),
            ),
            Text(
              amount,
              style: context.textStyles.titleMedium?.semiBold.withColor(
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNFCPayment(
      BuildContext context, LocalizationProvider localization) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(localization.translate('nfc_payment'),
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nfc,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              localization.translate('nfc_instruction'),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.translate('cancel')),
          ),
        ],
      ),
    );
  }
}
