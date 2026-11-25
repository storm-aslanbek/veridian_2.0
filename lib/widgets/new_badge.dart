import 'package:flutter/material.dart';

class NewBadge extends StatelessWidget {
  const NewBadge({
    super.key,
    required this.child,
    this.alignment = Alignment.topRight,
    this.inset = const EdgeInsets.all(6),
  });

  final Widget child;

  final Alignment alignment;
  final EdgeInsets inset;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: inset,
                child: Align(alignment: alignment, child: const _Pill()),
              ),
            ),
          ),
        ],
      );
}

class _Pill extends StatefulWidget {
  const _Pill();

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> with SingleTickerProviderStateMixin {
  static const _light = Color(0xFFFF5A6E);
  static const _red = Color(0xFFE5232F);

  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, label) {
          final position = _controller.value * 5 - 1.5;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .7)),
              gradient: LinearGradient(
                begin: Alignment(position - 1, -1),
                end: Alignment(position + 1, 1),
                colors: const [_red, Color(0xFFFF9AA4), _red],
              ),
              boxShadow: [
                BoxShadow(
                  color: _light.withValues(alpha: .55),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: label,
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 8, color: Colors.white),
              SizedBox(width: 2),
              Text(
                'NEW',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
        ),
      );
}
