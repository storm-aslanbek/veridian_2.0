import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/user_service.dart';
import 'access_code.dart';
import 'session_home.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key, this.changing = false});

  final bool changing;

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String? _pending;

  Future<String?> _save(String code) async {
    if (_pending == null) {
      setState(() => _pending = code);
      return null;
    }
    if (_pending != code) {
      setState(() => _pending = null);
      return uiText('Коды различаются. Введите новый код ещё раз.');
    }
    final userId = context.read<UserService>().currentUser?.id;
    if (userId == null) return uiText('Войдите в аккаунт повторно.');
    if (!await AccessCode.save(userId, code))
      return uiText('Не удалось сохранить код. Повторите попытку.');
    if (!mounted || context.read<UserService>().currentUser?.id != userId)
      return null;
    if (widget.changing) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute<void>(builder: (_) => const SessionHome()));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AccessCodeForm(
        title: _pending != null
            ? uiText('Повторите код доступа')
            : widget.changing
                ? uiText('Создайте новый код доступа')
                : uiText('Создайте код доступа'),
        subtitle: _pending != null
            ? uiText('Введите те же 4 цифры')
            : uiText('Введите 4 цифры для быстрого входа'),
        onEntered: _save,
        footer: widget.changing
            ? TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: Text(uiText('Отмена')))
            : null,
      );
}
