import 'package:flutter/material.dart';

class AiText extends StatelessWidget {
  const AiText(this.text, {super.key});

  final String text;

  static final _bullet = RegExp(r'^\s*[*-]\s+', multiLine: true);
  static final _heading = RegExp(r'^#{1,6}\s+', multiLine: true);

  @override
  Widget build(BuildContext context) {
    final parts =
        text.replaceAll(_heading, '').replaceAll(_bullet, '•  ').split('**');
    return SelectableText.rich(
      TextSpan(
        children: [
          for (final (index, part) in parts.indexed)
            TextSpan(
              text: part,
              style: index.isOdd
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
        ],
      ),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
    );
  }
}

class TypewriterText extends StatelessWidget {
  const TypewriterText(this.text, {super.key, required this.onDone});

  final String text;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return AiText(text);
    final characters = text.characters;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: characters.length),
      duration:
          Duration(milliseconds: (characters.length * 15).clamp(200, 3000)),
      onEnd: onDone,
      builder: (context, length, _) =>
          AiText(characters.take(length).toString()),
    );
  }
}
