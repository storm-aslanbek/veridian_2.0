import 'package:veridian/services/ui_strings.dart';
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.number,
    required this.caption,
    required this.onTap,
    this.expiry,
    this.visa = false,
  });

  final String balance;
  final String number;
  final String caption;
  final VoidCallback? onTap;
  final String? expiry;
  final bool visa;

  @override
  Widget build(BuildContext context) => _CardSurface(
        colors: const [Color(0xFF10B981), Color(0xFF065F46)],
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: Text('Veridian',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3)),
                  ),
                  const SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomPaint(painter: _Contactless())),
                ]),
                const SizedBox(height: 6),
                const SizedBox(
                    width: 36,
                    height: 28,
                    child: CustomPaint(painter: _EmvChip())),
                const Spacer(),
                Text(caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD4E8E5),
                        fontWeight: FontWeight.w600)),
                SizedBox(
                    height: 42,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(balance,
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 34,
                              letterSpacing: -.6)),
                    )),
                Row(children: [
                  Expanded(
                      child: Text(number,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFF1FFFA),
                              fontSize: 12,
                              letterSpacing: 1.6))),
                  if (expiry != null)
                    Text(expiry!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11)),
                  if (visa) ...[
                    const SizedBox(width: 9),
                    const Text('VISA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic)),
                  ],
                ]),
              ],
            ),
          ),
        ),
      );
}

class NewBalanceCard extends StatelessWidget {
  const NewBalanceCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _CardSurface(
        colors: const [Color(0xFF17365E), Color(0xFF10443D)],
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x26C0EBFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: Text(uiText('Открыть новую карту'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.colors, required this.child, this.onTap});
  final List<Color> colors;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
              color: Color(0x40081B22), blurRadius: 10, offset: Offset(0, 5)),
          BoxShadow(color: Color(0x4406151A), offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors),
            border: Border.all(color: const Color(0x449DDECB)),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const IgnorePointer(child: CustomPaint(painter: _CardFinish())),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFinish extends CustomPainter {
  const _CardFinish();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final reflection = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x36BCFFDF), Color(0x05FFFFFF), Color(0x2689A9E3)],
      stops: [0, .46, 1],
    ).createShader(bounds);
    canvas.drawRect(bounds, Paint()..shader = reflection);
    final stroke = Paint()
      ..color = const Color(0x219DEDDC)
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * .98, size.height * .94),
            width: size.width * (.47 + i * .15),
            height: size.height * (1.02 + i * .16)),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_CardFinish oldDelegate) => false;
}

class _EmvChip extends CustomPainter {
  const _EmvChip();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final gold = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFEDB3), Color(0xFFBD9248), Color(0xFFF9D989)],
    ).createShader(bounds);
    final outline =
        RRect.fromRectAndRadius(bounds.deflate(.6), const Radius.circular(5));
    canvas.drawRRect(outline, Paint()..shader = gold);
    final trace = Paint()
      ..color = const Color(0x995A411E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .85;
    canvas.drawRRect(outline, trace);
    final middle = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: bounds.center,
          width: size.width * .34,
          height: size.height * .43),
      const Radius.circular(2),
    );
    canvas.drawRRect(middle, trace);
    for (final y in [middle.top, middle.bottom]) {
      canvas.drawLine(Offset(1, y), Offset(middle.left, y), trace);
      canvas.drawLine(
          Offset(middle.right, y), Offset(size.width - 1, y), trace);
    }
    canvas.drawLine(Offset(bounds.center.dx, 1),
        Offset(bounds.center.dx, middle.top), trace);
    canvas.drawLine(Offset(bounds.center.dx, middle.bottom),
        Offset(bounds.center.dx, size.height - 1), trace);
  }

  @override
  bool shouldRepaint(_EmvChip oldDelegate) => false;
}

class _Contactless extends CustomPainter {
  const _Contactless();

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFFE9F4F5)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final radius in [5.0, 8.5, 12.0, 15.5]) {
      canvas.drawArc(
          Rect.fromCircle(center: Offset(3, size.height / 2), radius: radius),
          -.66,
          1.32,
          false,
          ink);
    }
  }

  @override
  bool shouldRepaint(_Contactless oldDelegate) => false;
}
