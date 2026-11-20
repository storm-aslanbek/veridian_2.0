import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/localization_provider.dart';
import '../../services/localization_service.dart';

extension AuthLanguageText on AppLanguage {
  String authText(String russian, String kazakh, String english) =>
      switch (this) {
        AppLanguage.ru => russian,
        AppLanguage.kk => kazakh,
        AppLanguage.en => english,
      };
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocalizationProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(children: [
      Flexible(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.eco_outlined, color: colors.primary, size: 22),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Veridian',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900, letterSpacing: -.8)),
          ),
        ]),
      ),
      const Spacer(),
      DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (value, title) in [
              (AppLanguage.en, 'EN'),
              (AppLanguage.kk, 'ҚАЗ'),
              (AppLanguage.ru, 'РУС')
            ])
              Semantics(
                selected: locale.currentLanguage == value,
                child: TextButton(
                  onPressed: () => locale.setLanguage(value),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    backgroundColor: locale.currentLanguage == value
                        ? colors.primaryContainer
                        : null,
                    foregroundColor: locale.currentLanguage == value
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  child: Text(title),
                ),
              ),
          ]),
        ),
      ),
    ]);
  }
}
