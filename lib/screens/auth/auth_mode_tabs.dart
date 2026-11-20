import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/localization_provider.dart';
import 'auth_header.dart';

class AuthModeTabs extends StatelessWidget {
  const AuthModeTabs(
      {super.key, required this.registering, required this.onSwitch});

  final bool registering;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = context.watch<LocalizationProvider>().currentLanguage.authText;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colors.primaryContainer,
          selectedForegroundColor: colors.onPrimaryContainer,
          backgroundColor: colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        segments: [
          ButtonSegment(
              value: false, label: Text(text('Вход', 'Кіру', 'Sign in'))),
          ButtonSegment(
              value: true,
              label: Text(text('Регистрация', 'Тіркелу', 'Register'))),
        ],
        selected: {registering},
        onSelectionChanged: onSwitch == null ? null : (_) => onSwitch!(),
      ),
    );
  }
}
