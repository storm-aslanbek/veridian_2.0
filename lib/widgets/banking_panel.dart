import 'package:veridian/services/ui_strings.dart';
import '../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme.dart';

class BankingPanel extends StatelessWidget {
  const BankingPanel({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(dark ? 20 : 18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: dark
              ? BorderSide(color: theme.colorScheme.outline)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
    );
  }
}

enum BankingTone {
  emerald(Color(0xFF10B981), Color(0xFF087654)),
  blue(Color(0xFF3B82F6), Color(0xFF2457A6)),
  amber(Color(0xFFF59E0B), Color(0xFF8E5405)),
  purple(Color(0xFF8B5CF6), Color(0xFF6542AF));

  const BankingTone(this.accent, this.ink);
  final Color accent;
  final Color ink;
}

class BankingIcon extends StatelessWidget {
  const BankingIcon(this.icon,
      {super.key, this.size = 44, this.tone = BankingTone.emerald});
  final IconData icon;
  final double size;
  final BankingTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark
            ? VeridianColors.surfaceStrong
            : tone.accent.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: size * .52, color: dark ? tone.accent : tone.ink),
    );
  }
}

class BankingHeading extends StatelessWidget {
  const BankingHeading(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      )),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class BankingThemeToggle extends StatelessWidget {
  const BankingThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return IconButton(
      tooltip:
          theme.isDarkMode ? uiText('Светлая тема') : uiText('Тёмная тема'),
      onPressed: theme.toggleTheme,
      icon: Icon(theme.isDarkMode
          ? Icons.light_mode_outlined
          : Icons.dark_mode_outlined),
    );
  }
}

class BankingCityPicker extends StatelessWidget {
  const BankingCityPicker(
      {super.key, required this.city, required this.onChanged});
  final String city;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: uiText('Выбрать город'),
        initialValue: city,
        onSelected: onChanged,
        itemBuilder: (_) => [
          for (final name in ['Тараз', 'Алматы', 'Астана'])
            PopupMenuItem(value: name, child: Text(uiText(name))),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_outlined, size: 19),
            const SizedBox(width: 4),
            Text(uiText(city)),
            const Icon(Icons.expand_more, size: 16),
          ]),
        ),
      );
}

String bankingAmount(num amount, [String currency = 'KZT']) {
  final formatted =
      NumberFormat('#,##0.##', LocalizationService().getLocaleCode())
          .format(amount);
  return "$formatted ${currency == 'KZT' ? '₸' : currency}";
}

Route<T> bankingRoute<T>(Widget screen) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 170),
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
          child: child,
        );
      },
    );

Future<T?> openBankingScreen<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(bankingRoute<T>(screen));

void bankingNotice(BuildContext context, String message) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(message, style: Theme.of(context).textTheme.titleMedium),
      ),
    ),
  );
}
