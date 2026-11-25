import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/assistant.dart';
import '../../services/ui_strings.dart';
import 'ai_effects.dart';
import 'ai_text.dart';

class AiChat extends StatefulWidget {
  const AiChat({
    super.key,
    required this.messages,
    required this.onSend,
    required this.greeting,
    required this.subtitle,
    required this.suggestions,
    required this.hint,
  });

  final List<AssistantMessage> messages;

  final Future<String?> Function(String question) onSend;
  final String greeting;
  final String subtitle;
  final List<String> suggestions;
  final String hint;

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> {
  final _controller = TextEditingController();

  late final _revealed = {...widget.messages};
  String? _pending;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _pending != null) return;
    setState(() {
      _pending = question;
      _error = null;
    });
    _controller.clear();

    final error = await widget.onSend(question);
    if (!mounted) return;
    setState(() {
      _pending = null;
      _error = error;
      if (error != null) _controller.text = question;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.messages.isEmpty && _pending == null;
    return Column(
      children: [
        Expanded(child: isEmpty ? _welcome() : _conversation()),
        if (_error != null) _errorBanner(_error!),
        _composer(),
      ],
    );
  }

  Widget _welcome() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const FadeSlideIn(child: AiOrb(size: 72)),
            const SizedBox(height: 20),
            FadeSlideIn(
              order: 1,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: aiAccentGradient.createShader,
                child: Text(widget.greeting,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              order: 2,
              child: Text(widget.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 24),
            for (final (index, suggestion) in widget.suggestions.indexed)
              FadeSlideIn(order: index + 3, child: _suggestion(suggestion)),
          ],
        ),
      ),
    );
  }

  Widget _suggestion(String text) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: aiColors[1].withValues(alpha: .35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          title: Text(text),
          trailing:
              Icon(Icons.north_east_rounded, size: 18, color: aiColors[1]),
          onTap: () => _send(text),
        ),
      ),
    );
  }

  Widget _conversation() {
    final pending = _pending;
    final items = <Widget>[
      for (final message in widget.messages)
        message.isUser ? _question(message.text) : _answer(message),
      if (pending != null) ...[_question(pending), _thinking()],
    ];
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: items.length,
      itemBuilder: (_, index) => items[items.length - 1 - index],
    );
  }

  Widget _question(String text) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.fromLTRB(48, 10, 0, 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: aiGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white)),
        ),
      );

  Widget _aiRow({required Widget child, bool thinking = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AiOrb(size: 30, thinking: thinking),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      );

  Widget _answer(AssistantMessage message) => KeyedSubtree(
        key: ObjectKey(message),
        child: _aiRow(
          child: _revealed.contains(message)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [AiText(message.text), _copyButton(message.text)],
                )
              : TypewriterText(
                  message.text,
                  onDone: () => setState(() => _revealed.add(message)),
                ),
        ),
      );

  Widget _copyButton(String text) => IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 16,
        tooltip: uiText('Копировать'),
        icon: const Icon(Icons.copy_rounded),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(uiText('Скопировано'))));
        },
      );

  Widget _thinking() => _aiRow(
        thinking: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            ThinkingLabel(phrases: [
              uiText('Читаю вопрос…'),
              uiText('Думаю…'),
              uiText('Формулирую ответ…'),
            ]),
            const SizedBox(height: 8),
            const SkeletonLines(),
          ],
        ),
      );

  Widget _errorBanner(String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
    );
  }

  Widget _composer() {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: aiColors[1].withValues(alpha: .45)),
          boxShadow: [
            BoxShadow(
              color: aiColors[1].withValues(alpha: .12),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            _sendButton(),
          ],
        ),
      ),
    );
  }

  Widget _sendButton() => ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, _) {
          final enabled = value.text.trim().isNotEmpty && _pending == null;
          final colors = Theme.of(context).colorScheme;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: enabled ? aiGradient : null,
              color: enabled ? null : colors.surfaceContainerHighest,
            ),
            child: IconButton(
              tooltip: uiText('Отправить'),
              onPressed: enabled ? () => _send(value.text) : null,
              color: Colors.white,
              disabledColor: colors.onSurfaceVariant,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          );
        },
      );
}
