import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/phone_formatter.dart';
import '../../pin_code.dart';
import '../../providers/localization_provider.dart';
import '../../services/localization_service.dart';
import '../../services/user_service.dart';
import '../../widgets/banking_panel.dart';
import 'access_code.dart';
import 'auth_header.dart';
import 'auth_mode_tabs.dart';
import 'demo_session.dart';
import 'register_screen.dart';
import 'session_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _failure(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login(AppLanguage language) async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final users = context.read<UserService>();
    final success = await users.login(
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (success && users.isAuthenticated) {
      Navigator.of(context)
          .pushReplacement(bankingRoute<void>(const SessionHome()));
    } else {
      _failure(language.authText(
        'Проверьте номер телефона и пароль.',
        'Телефон нөмірі мен құпиясөзді тексеріңіз.',
        'Check your phone number and password.',
      ));
    }
  }

  Future<void> _pinLogin(AppLanguage language) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final users = context.read<UserService>();
    await users.loadCurrentUser();
    if (!mounted) return;
    final user = users.currentUser;
    if (user != null && AccessCode.enabled(user.id)) {
      Navigator.of(context)
          .pushReplacement(bankingRoute<void>(const PinCode()));
    } else {
      _failure(language.authText(
        'Для этого аккаунта войдите по телефону и паролю.',
        'Бұл аккаунтқа телефон нөмірі мен құпиясөз арқылы кіріңіз.',
        'Use your phone number and password to sign in to this account.',
      ));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = context.watch<LocalizationProvider>().currentLanguage;
    final text = language.authText;
    final showPin = AccessCode.hasSavedSignIn;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(),
                  const SizedBox(height: 32),
                  Text(
                      text('Вход в аккаунт', 'Аккаунтқа кіру',
                          'Sign in to Veridian'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      )),
                  const SizedBox(height: 16),
                  AuthModeTabs(
                    registering: false,
                    onSwitch: _isLoading
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                              bankingRoute<void>(const RegisterScreen()),
                            ),
                  ),
                  const SizedBox(height: 12),
                  BankingPanel(
                    padding: 18,
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _phoneController,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  labelText: text('Номер телефона',
                                      'Телефон нөмірі', 'Phone number'),
                                  hintText: '+7 (___) ___-__-__',
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [PhoneInputFormatter()],
                                autofillHints: const [
                                  AutofillHints.telephoneNumber
                                ],
                                validator: (value) => value == null ||
                                        value
                                                .replaceAll(RegExp(r'\D'), '')
                                                .length !=
                                            11
                                    ? text(
                                        'Введите полный номер',
                                        'Нөмірді толық енгізіңіз',
                                        'Enter your full phone number')
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  labelText:
                                      text('Пароль', 'Құпиясөз', 'Password'),
                                  hintText: '••••••',
                                ),
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                validator: (value) =>
                                    (value ?? '').trim().isEmpty
                                        ? text(
                                            'Введите пароль',
                                            'Құпиясөзді енгізіңіз',
                                            'Enter your password')
                                        : null,
                                onFieldSubmitted: (_) => _login(language),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: const Color(0xFF052E23),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13)),
                                  textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800),
                                ),
                                onPressed:
                                    _isLoading ? null : () => _login(language),
                                child: _isLoading
                                    ? const SizedBox.square(
                                        dimension: 19,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Text(text('Войти', 'Кіру', 'Sign in')),
                              ),
                              if (showPin) ...[
                                const SizedBox(height: 5),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _pinLogin(language),
                                  child: Text(text('Войти по PIN',
                                      'PIN арқылы кіру', 'Sign in with PIN')),
                                ),
                              ],
                            ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10)),
                      onPressed: _isLoading
                          ? null
                          : () => openBankingScreen<void>(
                              context, const DemoSession()),
                      icon: const Icon(Icons.play_circle_outline_rounded,
                          size: 18),
                      label: Text(text('Демо-вход', 'Демоға кіру', 'Try demo')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
