import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:veridian/services/business_service.dart';
import 'package:veridian/widgets/action_button.dart';
import 'package:veridian/providers/localization_provider.dart'; // Добавлен

class BusinessCheckScreen extends StatefulWidget {
  const BusinessCheckScreen({super.key});

  @override
  State<BusinessCheckScreen> createState() => _BusinessCheckScreenState();
}

class _BusinessCheckScreenState extends State<BusinessCheckScreen> {
  final _binController = TextEditingController();

  @override
  void dispose() {
    _binController.dispose();
    super.dispose();
  }

  void _setDemoBin(String bin) {
    setState(() {
      _binController.text = bin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessService = context.watch<BusinessService>();
    final localization = context.watch<LocalizationProvider>(); // Провайдер
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(localization.translate('check_business'),
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('check_counterparty'), // Ключ
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.translate('check_counterparty_desc'), // Ключ
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _binController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText:
                          localization.translate('bin_iin_label'), // Ключ
                      hintText:
                          localization.translate('enter_12_digits'), // Ключ
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surfaceContainerHighest
                          : const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(localization.translate('quick_demo'),
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)), // Ключ
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDemoButton(
                          uiText('Аким.Тараз'), "991040001837", theme),
                      _buildDemoButton("ZHPHC", "990640001201", theme),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ActionButton(
                      label: localization.translate('btn_check'), // Ключ
                      isFullWidth: true,
                      onPressed: () {
                        if (businessService.isLoading) return;
                        FocusScope.of(context).unfocus();
                        context
                            .read<BusinessService>()
                            .checkBusiness(_binController.text);
                      }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (businessService.isLoading)
              Center(
                  child: CircularProgressIndicator(color: theme.primaryColor))
            else if (businessService.error != null)
              _buildErrorCard(uiText(businessService.error!))
            else if (businessService.result != null)
              _buildResultCard(context, businessService.result!, localization),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoButton(String label, String bin, ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () => _setDemoBin(bin),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
            side: BorderSide(color: Colors.grey.shade300),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
              Text("${bin.substring(0, 4)}...",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
      BuildContext context, dynamic info, LocalizationProvider localization) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade100),
            boxShadow: [
              BoxShadow(
                  color: Colors.green.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business,
                        color: Colors.green, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.nameRu?.isNotEmpty == true
                              ? info.nameString
                              : uiText('Название не найдено'),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            "${localization.translate('bin_iin_label')}: ${info.bin?.isNotEmpty == true ? info.binString : uiText('Не указан')}",
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(localization.translate('total_rating'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (info.totalRating ?? 0) > 0
                          ? Colors.green
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${info.totalRating?.toStringAsFixed(2) ?? 'N/A'}",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildDetailRow(
                  context,
                  localization.translate('legal_address'),
                  info.customerLegalAddress ??
                      localization.translate('not_specified')),
              const Divider(),
              _buildDetailRow(
                  context,
                  localization.translate('bank_name'),
                  info.customerBankNameRu ??
                      localization.translate('not_specified')),
              const Divider(),
              _buildDetailRow(context, localization.translate('total_paid_tax'),
                  "${info.fullyPaid ?? 0} %"),
              const Divider(),
              _buildDetailRow(
                  context,
                  localization.translate('terminated_contracts'),
                  "${info.terminatedContracts ?? 0}"),
              const Divider(),
              _buildDetailRow(
                  context,
                  localization.translate('avg_payment_time'),
                  "${info.averagePaymentTime?.toStringAsFixed(1) ?? '-'} ${localization.translate('days_short')}"),
              const Divider(),
              _buildDetailRow(
                  context,
                  localization.translate('avg_signing_time'),
                  "${info.averageSigningTime?.toStringAsFixed(1) ?? '-'} ${localization.translate('days_short')}"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 16),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
              child: Text(error, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
