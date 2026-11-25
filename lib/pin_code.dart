import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'screens/auth/access_code.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/session_home.dart';
import 'services/user_service.dart';

class PinCode extends StatefulWidget {
  const PinCode({super.key, this.verifyOnly = false});

  final bool verifyOnly;

  @override
  State<PinCode> createState() => _PinCodeState();
}

class _PinCodeState extends State<PinCode> {
  final _auth = LocalAuthentication();
  bool _busy = false;
  bool _biometrics = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        !widget.verifyOnly &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      if (mounted) setState(() => _biometrics = available.isNotEmpty);
    } on PlatformException {
      // PIN entry remains available.
    } on MissingPluginException {
      // PIN entry remains available.
    }
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final verified = await _auth.authenticate(
        localizedReason: uiText('Войдите в приложение'),
        options:
            const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (verified && mounted) _unlock();
    } on PlatformException {
      // PIN entry remains available.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _verify(String code) async {
    final user = context.read<UserService>().currentUser;
    if (user == null ||
        !AccessCode.enabled(user.id) ||
        AccessCode.read(user.id) != code) {
      return uiText('Неверный код доступа');
    }
    _unlock();
    return null;
  }

  void _unlock() {
    final user = context.read<UserService>().currentUser;
    if (user == null || !AccessCode.enabled(user.id)) return;
    if (widget.verifyOnly) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute<void>(builder: (_) => const SessionHome()));
    }
  }

  Future<void> _passwordLogin() async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.read<UserService>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) => AccessCodeForm(
        title: uiText('Введите код доступа'),
        subtitle: widget.verifyOnly
            ? uiText('Подтвердите текущий код')
            : uiText('Разблокируйте Veridian'),
        onEntered: _verify,
        busy: _busy,
        extraKey: _biometrics
            ? IconButton(
                tooltip: uiText('Войти по биометрии'),
                onPressed: _busy ? null : _authenticate,
                icon: const Icon(Icons.fingerprint_rounded),
              )
            : null,
        footer: TextButton(
          onPressed: _busy
              ? null
              : widget.verifyOnly
                  ? () => Navigator.maybePop(context)
                  : _passwordLogin,
          child: Text(
              widget.verifyOnly
                  ? uiText('Отмена')
                  : uiText('Войти по паролю / Сменить аккаунт'),
              textAlign: TextAlign.center),
        ),
      );
}
