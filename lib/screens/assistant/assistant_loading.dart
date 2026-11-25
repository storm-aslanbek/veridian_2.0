import 'package:flutter/material.dart';

import '../../services/ui_strings.dart';
import '../../widgets/ai/ai_effects.dart';
import '../../widgets/banking_panel.dart';

class AssistantLoading extends StatelessWidget {
  const AssistantLoading({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: 12),
          const AiOrb(size: 64, thinking: true),
          const SizedBox(height: 16),
          ThinkingLabel(phrases: [
            uiText('Собираю операции…'),
            uiText('Считаю расходы по категориям…'),
            uiText('Готовлю сводку…'),
          ]),
          const SizedBox(height: 20),
          for (var index = 0; index < 3; index++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: BankingPanel(child: SkeletonLines(widths: [.45, 1, .8])),
            ),
        ],
      );
}
