import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // 1. Получаем только цифры из нового значения
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 2. Если цифр нет или их мало, гарантируем +7
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '+7 (',
        selection: TextSelection.collapsed(offset: 4),
      );
    }

    // 3. Если первая цифра 8 или 7, мы считаем её кодом страны и игнорируем (так как +7 у нас фиксировано)
    // Но если пользователь ввел 7 или 8 как часть кода оператора (например 777...), нужно быть аккуратным.
    // В этой реализации мы считаем, что первая 7-ка - это код страны.

    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = digits.substring(1);
    }

    // Ограничиваем длину (10 цифр после +7)
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    // 4. Строим маску +7 (XXX) XXX-XX-XX
    final buffer = StringBuffer();
    buffer.write('+7 (');

    for (int i = 0; i < digits.length; i++) {
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      if (i == 8) buffer.write('-');
      buffer.write(digits[i]);
    }

    // Если цифр нет (кроме удаленной 7ки), оставляем скобку
    if (digits.isEmpty) {
      // уже записали +7 (
    }

    final String result = buffer.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}