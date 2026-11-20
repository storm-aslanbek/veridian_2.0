import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veridian/screens/auth/register_screen.dart';
import 'package:veridian/screens/auth/set_pin_screen.dart';
import 'package:veridian/services/user_service.dart';
import 'package:veridian/services/account_service.dart';
import 'package:veridian/services/card_service.dart'; // Добавим для полной загрузки
import 'package:veridian/models/phone_formatter.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 1. Выполняем вход
    final userService = context.read<UserService>();
    final success = await userService.login(
      _phoneController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      debugPrint("Login successful, navigating to SetPinScreen...");

      // 2. СНАЧАЛА навигация (используем push, чтобы избежать черного экрана)
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SetPinScreen()),
      );

      // 3. ПОТОМ загрузка данных в фоне (чтобы не задерживать переход)
      final userId = userService.currentUser?.id;
      if (userId != null) {
        // Запускаем загрузку, не ожидая её завершения для UI
        context.read<AccountService>().loadAccounts(userId);
        context
            .read<CardService>()
            .loadCards(userId, userService.currentUser!.firstName);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uiText('Ошибка входа. Проверьте номер и пароль.')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(uiText('Вход'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: uiText('Телефон'),
                  hintText: '+7 (___) ___-__-__',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                validator: (v) =>
                    v!.length < 18 ? uiText('Введите полный номер') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: uiText('Пароль'),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) => v!.isEmpty ? uiText('Введите пароль') : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(uiText('Войти')),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(uiText('Нет аккаунта? Зарегистрироваться')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
