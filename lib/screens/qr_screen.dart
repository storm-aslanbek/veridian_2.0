import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart'; // Добавляем Provider
import 'package:veridian/providers/localization_provider.dart'; // И провайдер локализации

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool isScanned = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = Tween<double>(begin: -0.9, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем локализацию и тему из контекста
    final localization = context.watch<LocalizationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localization.translate('title_qr_scan'),
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface, // Адаптивный цвет фона AppBar
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface), // Адаптивный цвет иконок
        actions: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!isScanned) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    setState(() {
                      isScanned = true;
                    });
                    final code = barcode.rawValue!;
                    debugPrint('QR Found: $code');
                    _showResultDialog(context, code, localization);
                    break;
                  }
                }
              }
            },
          ),
          _buildOverlay(context, localization),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, String code, LocalizationProvider localization) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
        title: Text(localization.translate('qr_found')),
        content: SelectableText("${localization.translate('code_label')}: $code"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isScanned = false;
              });
            },
            child: Text(localization.translate('ok')),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, LocalizationProvider localization) {
    return Column(
      children: [
        Expanded(child: Container(color: Colors.black54)),
        Row(
          children: [
            Expanded(child: Container(color: Colors.black54)),

            // Сканерлеу аймағы
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                // Сызық шеңберден шығып кетпес үшін
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Қозғалатын сызық
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(0, _animation.value),
                          child: Container(
                            height: 2,
                            width: 240,
                            color: Colors.red,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            Expanded(child: Container(color: Colors.black54)),
          ],
        ),
        Expanded(
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Text(
                localization.translate('qr_scan_desc'),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}