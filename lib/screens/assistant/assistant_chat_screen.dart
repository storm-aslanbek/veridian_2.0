import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/localization_provider.dart';
import '../../services/api_client.dart';
import '../../services/assistant_service.dart';
import '../../services/ui_strings.dart';
import '../../widgets/ai/ai_chat.dart';

class AssistantChatScreen extends StatelessWidget {
  const AssistantChatScreen({super.key});

  Future<String?> _ask(BuildContext context, String question) async {
    final service = context.read<AssistantService>();
    final language = context.read<LocalizationProvider>().currentLanguage.name;
    try {
      await service.ask(question, language);
      return null;
    } catch (e) {
      debugPrint('Assistant chat error: $e');
      return _errorText(e);
    }
  }

  String _errorText(Object error) =>
      switch (error is ApiException ? error.statusCode : null) {
        503 => uiText('ИИ сейчас перегружен. Попробуйте чуть позже.'),
        _ => uiText('Не удалось связаться с сервером. Попробуйте ещё раз.'),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(uiText('Вопрос аналитику'))),
        body: AiChat(
          messages: context.watch<AssistantService>().messages,
          onSend: (question) => _ask(context, question),
          greeting: uiText('Спросите о своих финансах'),
          subtitle: uiText('Отвечаю на основе вашей сводки за месяц.'),
          suggestions: [
            uiText('Где я могу сэкономить?'),
            uiText('Хватит ли мне денег до конца месяца?'),
            uiText('На что я трачу больше всего?'),
          ],
          hint: uiText('Спросите что-нибудь'),
        ),
      );
}
