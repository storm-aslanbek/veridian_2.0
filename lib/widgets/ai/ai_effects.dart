import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const aiColors = [Color(0xFF34D399), Color(0xFF00A87E), Color(0xFF0F8F83)];

const aiGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF18483F), Color(0xFF087654), Color(0xFF0E8F6E)],
);

const aiAccentGradient = LinearGradient(colors: aiColors);

class _Loop extends StatefulWidget {
  const _Loop(
      {required this.duration, required this.builder, this.active = true});

  final Duration duration;
  final bool active;
  final Widget Function(BuildContext context, double progress) builder;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: widget.duration);

  void _sync() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Loop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(context, _controller.value),
      );
}

class AiOrb extends StatelessWidget {
  const AiOrb({super.key, this.size = 32, this.thinking = false});

  final double size;
  final bool thinking;

  @override
  Widget build(BuildContext context) => _Loop(
        duration: const Duration(milliseconds: 1600),
        active: thinking,
        builder: (context, progress) {
          final angle = progress * 2 * math.pi;
          final pulse = thinking ? math.sin(angle) : 0.0;
          return Transform.scale(
            scale: 1 + pulse * .07,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [...aiColors, aiColors.first],
                  transform: GradientRotation(angle),
                ),
                boxShadow: [
                  BoxShadow(
                    color: aiColors[1].withValues(alpha: .3 + pulse * .15),
                    blurRadius: size * .4,
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  size: size * .55, color: Colors.white),
            ),
          );
        },
      );
}

class Shimmer extends StatelessWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return _Loop(
      duration: const Duration(milliseconds: 1500),
      builder: (context, progress) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            color.withValues(alpha: .18),
            aiColors[1].withValues(alpha: .85),
            color.withValues(alpha: .18),
          ],
          stops: const [.35, .5, .65],
          transform: _Slide(progress * 2 - 1),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.offset);

  final double offset;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * offset, 0, 0);
}

class ThinkingLabel extends StatefulWidget {
  const ThinkingLabel({super.key, required this.phrases});

  final List<String> phrases;

  @override
  State<ThinkingLabel> createState() => _ThinkingLabelState();
}

class _ThinkingLabelState extends State<ThinkingLabel> {
  late final Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (_index < widget.phrases.length - 1) setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Shimmer(
          key: ValueKey(_index),
          child: Text(widget.phrases[_index],
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
}

class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.widths = const [1, .85, .6]});

  final List<double> widths;

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final width in widths)
              FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
      );
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.order = 0});

  final Widget child;
  final int order;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = order * 90;
    final total = delay + 350;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, (1 - value) * 16), child: child),
      ),
      child: child,
    );
  }
}
