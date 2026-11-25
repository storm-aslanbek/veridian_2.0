import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veridian/models/assistant.dart';
import 'package:veridian/providers/localization_provider.dart';
import 'package:veridian/services/support_service.dart';
import 'package:veridian/services/ui_strings.dart';
import 'package:veridian/widgets/ai/ai_chat.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final List<AssistantMessage> _messages = [];

  static const _faqDatabase = <String, Map<String, String>>{
    'ru': {
      "Как изменить пароль?":
          "Перейдите в Профиль -> Настройки -> Безопасность -> Смена пароля.",
      "Где найти банкомат?":
          "На главной странице нажмите на кнопку 'Банк на карте' в разделе 'Полезное'.",
      "Как перевести деньги?":
          "Используйте вкладку 'Переводы' в нижнем меню или быструю кнопку на главной.",
      "Лимиты по картам":
          "Вы можете настроить лимиты в разделе 'Карты' -> Настройки карты.",
    },
    'kk': {
      "Құпия сөзді қалай өзгертуге болады?":
          "Профиль -> Баптаулар -> Қауіпсіздік -> Құпия сөзді өзгерту бөліміне өтіңіз.",
      "Банкоматты қайдан табуға болады?":
          "Басты беттегі 'Пайдалы' бөліміндегі 'Картадағы банк' түймесін басыңыз.",
      "Ақшаны қалай аударуға болады?":
          "Төменгі мәзірдегі 'Аударымдар' қойындысын немесе басты беттегі жылдам түймені пайдаланыңыз.",
      "Карта лимиттері":
          "Сіз лимиттерді 'Карталар' -> Карта баптаулары бөлімінде реттей аласыз.",
    },
    'en': {
      "How to change password?":
          "Go to Profile -> Settings -> Security -> Change Password.",
      "Where to find an ATM?":
          "Click on 'Bank on Map' in the 'Useful' section on the Home page.",
      "How to transfer money?":
          "Use the 'Transfer' tab in the bottom menu or the quick button on the home screen.",
      "Card limits":
          "You can adjust limits in the 'Cards' -> Card Settings section.",
    }
  };

  Map<String, String> _faq(String language) =>
      _faqDatabase[language] ?? _faqDatabase['ru']!;

  Future<String?> _answer(String question, String language) async {
    for (final entry in _faq(language).entries) {
      if (question.toLowerCase().contains(entry.key.toLowerCase())) {
        await Future.delayed(const Duration(milliseconds: 900));
        return entry.value;
      }
    }
    return context.read<SupportService>().sendMessage(question, language);
  }

  Future<String?> _send(String question) async {
    final language = context.read<LocalizationProvider>().currentLanguage.name;
    final reply = await _answer(question, language);
    if (!mounted) return null;
    if (reply == null) {
      return uiText('Не удалось связаться с сервером. Попробуйте ещё раз.');
    }
    setState(() => _messages.addAll([
          AssistantMessage(question, isUser: true),
          AssistantMessage(reply, isUser: false),
        ]));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LocalizationProvider>().currentLanguage.name;
    return Scaffold(
      appBar: AppBar(title: Text(uiText('Поддержка'))),
      body: AiChat(
        messages: _messages,
        onSend: _send,
        greeting: uiText('Чем могу помочь?'),
        subtitle: uiText('Я виртуальный помощник Veridian.'),
        suggestions: _faq(language).keys.toList(),
        hint: uiText('Спросите что-нибудь'),
      ),
    );
  }
}
