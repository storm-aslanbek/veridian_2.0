import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pin_code.dart';
import '../services/user_service.dart';
import '../widgets/banking_panel.dart';
import 'auth/access_code.dart';
import 'auth/login_screen.dart';
import 'auth/demo_session.dart';
import 'auth/set_pin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showPhone = false;
  bool _showIin = false;
  bool _leaving = false;

  String _maskedPhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) digits = '7$digits';
    if (digits.length != 11) return '••• ••• •• ••';
    final prefix = digits.startsWith('8') ? '7' : digits[0];
    return '+$prefix ${digits.substring(1, 4)} ••• •• ${digits.substring(9)}';
  }

  String _maskedIin(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 12
        ? '${digits.substring(0, 4)}••••••••'
        : '••••••••••••';
  }

  Future<void> _changePin(String userId) async {
    setState(() {
      _showPhone = false;
      _showIin = false;
    });
    if (AccessCode.enabled(userId)) {
      final confirmed = await openBankingScreen<bool>(
          context, const PinCode(verifyOnly: true));
      if (!mounted || confirmed != true) return;
    }
    if (!mounted || context.read<UserService>().currentUser?.id != userId)
      return;
    final saved = await openBankingScreen<bool>(
        context, const SetPinScreen(changing: true));
    if (!mounted || saved != true) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(uiText('Код доступа обновлён'))));
  }

  Future<void> _logout() async {
    if (_leaving) return;
    if (isBankingDemo(context)) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    setState(() {
      _leaving = true;
      _showPhone = false;
      _showIin = false;
    });
    final navigator = Navigator.of(context);
    await context.read<UserService>().logout();
    if (!navigator.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUser;
    if (user == null) return const Scaffold();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(uiText('Профиль')),
          actions: const [BankingThemeToggle()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BankingPanel(
            padding: 24,
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF087659), Color(0xFF173752)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x33065F46),
                          blurRadius: 16,
                          offset: Offset(0, 6))
                    ],
                  ),
                  child: Text(
                    user.firstName.isEmpty
                        ? 'V'
                        : user.firstName.characters.first.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                    isBankingDemo(context)
                        ? uiText(user.fullName.trim())
                        : user.fullName.trim(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Chip(
                  avatar: Icon(Icons.check_circle_rounded,
                      size: 17, color: colors.onPrimaryContainer),
                  label: Text(uiText('Аккаунт активен'),
                      style: TextStyle(color: colors.onPrimaryContainer)),
                  backgroundColor: colors.primaryContainer,
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BankingPanel(
              padding: 0,
              child: Column(children: [
                _detail(
                    context,
                    uiText('Телефон'),
                    _showPhone ? user.phone : _maskedPhone(user.phone),
                    Icons.phone_rounded,
                    _showPhone,
                    () => setState(() => _showPhone = !_showPhone)),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _detail(
                    context,
                    uiText('ИИН'),
                    _showIin ? user.iin : _maskedIin(user.iin),
                    Icons.badge_rounded,
                    _showIin,
                    () => setState(() => _showIin = !_showIin)),
              ])),
          const SizedBox(height: 20),
          BankingPanel(
              padding: 0,
              child: Column(children: [
                if (!isBankingDemo(context)) ...[
                  ListTile(
                    leading: const BankingIcon(Icons.pin_rounded,
                        tone: BankingTone.blue),
                    title: Text(AccessCode.enabled(user.id)
                        ? uiText('Сменить код доступа')
                        : uiText('Включить PIN-код')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _leaving ? null : () => _changePin(user.id),
                  ),
                  if (AccessCode.enabled(user.id)) ...[
                    ListTile(
                      leading: const BankingIcon(Icons.lock_rounded),
                      title: Text(uiText('Заблокировать по PIN')),
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          bankingRoute<void>(const PinCode()), (_) => false),
                    ),
                    ListTile(
                      title: Text(uiText('Отключить PIN-код')),
                      onTap: () async {
                        final verified = await openBankingScreen<bool>(
                            context, const PinCode(verifyOnly: true));
                        if (!mounted || verified != true) return;
                        await AccessCode.disable(user.id);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ],
                ListTile(
                  enabled: !_leaving,
                  leading: const BankingIcon(Icons.lock_reset_rounded,
                      tone: BankingTone.purple),
                  title: Text(uiText('Сменить пароль')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _leaving
                      ? null
                      : () => bankingNotice(context,
                          uiText('Смена пароля пока недоступна в приложении.')),
                ),
              ])),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _leaving ? null : _logout,
            style: OutlinedButton.styleFrom(foregroundColor: colors.error),
            icon: const Icon(Icons.logout_rounded),
            label: Text(uiText('Выйти из аккаунта')),
          ),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value,
          IconData icon, bool visible, VoidCallback toggle) =>
      ListTile(
        leading: BankingIcon(icon),
        title: Text(label, style: Theme.of(context).textTheme.bodySmall),
        subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
        trailing: IconButton(
          tooltip: uiText(visible ? 'Скрыть {0}' : 'Показать {0}', label),
          onPressed: toggle,
          icon: Icon(visible
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded),
        ),
      );
}
