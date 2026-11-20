import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veridian/screens/auth/login_screen.dart';
import 'package:veridian/services/user_service.dart';
import '../../providers/localization_provider.dart';
import 'auth_header.dart';
import 'package:veridian/models/phone_formatter.dart';
import '../../widgets/banking_panel.dart';
import 'session_home.dart';
import 'auth_mode_tabs.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _surnameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _iinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+7 (';
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _iinController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String patronymicValue = _patronymicController.text.trim();
    final String? patronymic = patronymicValue.isEmpty ? null : patronymicValue;

    final userService = context.read<UserService>();

    // Регистрация и автоматический логин внутри сервиса
    final success = await userService.register(
      surname: _surnameController.text.trim(),
      firstName: _firstNameController.text.trim(),
      patronymic: patronymic,
      iin: _iinController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text,
    );

    if (!mounted) return;

    final user = userService.currentUser;
    if (success && user != null) {
      Navigator.of(context)
          .pushReplacement(bankingRoute<void>(const SessionHome()));
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                context.read<LocalizationProvider>().currentLanguage.authText(
                      'Проверьте данные для регистрации.',
                      'Тіркелу деректерін тексеріңіз.',
                      'Check your registration details.',
                    ))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = context.watch<LocalizationProvider>().currentLanguage.authText;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(),
                    const SizedBox(height: 32),
                    Text(
                        text('Создать аккаунт', 'Аккаунт ашу',
                            'Create an account'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800, letterSpacing: -.6)),
                    const SizedBox(height: 16),
                    AuthModeTabs(
                      registering: true,
                      onSwitch: _isLoading
                          ? null
                          : () => Navigator.pushReplacement(
                              context, bankingRoute<void>(const LoginScreen())),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _surnameController,
                      decoration: InputDecoration(
                          labelText: text('Фамилия', 'Тегі', 'Last name'),
                          prefixIcon: const Icon(Icons.person)),
                      validator: (v) => v!.isEmpty
                          ? text('Обязательное поле', 'Міндетті өріс',
                              'Required field')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                          labelText: text('Имя', 'Аты', 'First name'),
                          prefixIcon: const Icon(Icons.person_outline)),
                      validator: (v) => v!.isEmpty
                          ? text('Обязательное поле', 'Міндетті өріс',
                              'Required field')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _patronymicController,
                      decoration: InputDecoration(
                          labelText: text(
                              'Отчество (если есть)',
                              'Әкесінің аты (бар болса)',
                              'Patronymic (optional)'),
                          prefixIcon: const Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _iinController,
                      decoration: InputDecoration(
                          labelText: text(
                              'ИИН', 'ЖСН', 'Individual identification number'),
                          prefixIcon: const Icon(Icons.badge)),
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                      validator: (v) => v!.length != 12
                          ? text(
                              'Введите 12 цифр ИИН',
                              'ЖСН-нің 12 цифрын енгізіңіз',
                              'Enter all 12 digits')
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                        text(
                            'Контакты и безопасность',
                            'Байланыс және қауіпсіздік',
                            'Contact and security'),
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: text(
                            'Номер телефона', 'Телефон нөмірі', 'Phone number'),
                        hintText: '+7 (777) 000-00-00',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneInputFormatter()],
                      validator: (v) {
                        final digits = v!.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 11)
                          return text(
                              'Введите полный номер',
                              'Нөмірді толық енгізіңіз',
                              'Enter your full phone number');
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                          labelText: text('Пароль', 'Құпиясөз', 'Password'),
                          prefixIcon: const Icon(Icons.lock)),
                      obscureText: true,
                      validator: (v) => v!.length < 6
                          ? text('Минимум 6 символов', 'Кемінде 6 таңба',
                              'At least 6 characters')
                          : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(text('Зарегистрироваться', 'Тіркелу',
                                'Create account')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
