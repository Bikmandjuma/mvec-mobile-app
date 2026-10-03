import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Custom Lucide-like icon set matching the frontend `Icon.jsx`.
class MvIcon extends StatelessWidget {
  const MvIcon(this.name, {super.key, this.size = 18, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color;
    return CustomPaint(
      size: Size(size, size),
      painter: _IconPainter(name, c ?? MvColors.ink),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.name, this.color);
  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void l(Offset a, Offset b) {
      canvas.drawLine(Offset(a.dx * s, a.dy * s), Offset(b.dx * s, b.dy * s), stroke);
    }

    void circle(Offset c, double r, {bool fill = false}) {
      final paint = Paint()
        ..color = color
        ..style = fill ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.8 * s;
      canvas.drawCircle(Offset(c.dx * s, c.dy * s), r * s, paint);
    }

    void rect(double x, double y, double w, double h, {double r = 0}) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * s, y * s, w * s, h * s),
          Radius.circular(r * s),
        ),
        paint,
      );
    }

    void path(List<Offset> pts, {bool close = false}) {
      final path = Path()..moveTo(pts.first.dx * s, pts.first.dy * s);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx * s, p.dy * s);
      }
      if (close) path.close();
      canvas.drawPath(path, stroke);
    }

    switch (name) {
      case 'grid':
        rect(3, 3, 7, 7, r: 1);
        rect(14, 3, 7, 7, r: 1);
        rect(3, 14, 7, 7, r: 1);
        rect(14, 14, 7, 7, r: 1);
        break;
      case 'home':
        path([const Offset(3, 10.5), const Offset(12, 3), const Offset(21, 10.5), const Offset(21, 21), const Offset(3, 21)], close: true);
        l(const Offset(9, 21), const Offset(9, 14));
        l(const Offset(15, 21), const Offset(15, 14));
        break;
      case 'users':
        circle(const Offset(9, 8), 3.5);
        path([const Offset(2.5, 20), const Offset(2.5, 17), const Offset(15.5, 17), const Offset(15.5, 20)]);
        circle(const Offset(17, 8.5), 2.5);
        l(const Offset(17, 14), const Offset(21.5, 14));
        l(const Offset(21.5, 14), const Offset(21.5, 20));
        break;
      case 'user':
        circle(const Offset(12, 8), 4);
        path([const Offset(4, 21), const Offset(4, 18), const Offset(20, 18), const Offset(20, 21)], close: true);
        break;
      case 'shop':
        path([const Offset(4, 9), const Offset(20, 9), const Offset(21, 4), const Offset(3, 4)], close: true);
        path([const Offset(5, 9), const Offset(5, 21), const Offset(19, 21), const Offset(19, 9)]);
        l(const Offset(10, 21), const Offset(10, 14));
        l(const Offset(14, 14), const Offset(14, 21));
        break;
      case 'box':
        path([const Offset(12, 3), const Offset(21, 7.5), const Offset(21, 16.5), const Offset(12, 21), const Offset(3, 16.5), const Offset(3, 7.5)], close: true);
        l(const Offset(3, 7.5), const Offset(12, 12));
        l(const Offset(21, 7.5), const Offset(12, 12));
        l(const Offset(12, 12), const Offset(12, 21));
        break;
      case 'tag':
        path([const Offset(3, 12), const Offset(12, 3), const Offset(21, 3), const Offset(21, 12), const Offset(12, 21)], close: true);
        circle(const Offset(16.5, 7.5), 1.5, fill: true);
        break;
      case 'cart':
        circle(const Offset(9, 20), 1.5, fill: true);
        circle(const Offset(18, 20), 1.5, fill: true);
        path([const Offset(2.5, 3.5), const Offset(4.5, 3.5), const Offset(7, 15.5), const Offset(18.5, 15.5), const Offset(21, 6.5), const Offset(5.5, 6.5)]);
        break;
      case 'wallet':
        rect(3, 6, 18, 14, r: 2.5);
        l(const Offset(3, 10), const Offset(21, 10));
        circle(const Offset(17, 15), 1.3, fill: true);
        break;
      case 'chart':
        l(const Offset(4, 20), const Offset(4, 12));
        l(const Offset(10, 20), const Offset(10, 8));
        l(const Offset(16, 20), const Offset(16, 14));
        l(const Offset(22, 20), const Offset(22, 4));
        break;
      case 'bell':
        path([const Offset(6, 9), const Offset(6, 14), const Offset(18, 14), const Offset(18, 9)], close: true);
        path([const Offset(4.5, 14), const Offset(5.5, 15.5), const Offset(7, 17.5)], close: true);
        path([const Offset(19.5, 14), const Offset(18.5, 15.5), const Offset(17, 17.5)], close: true);
        path([const Offset(9.5, 18), const Offset(9.5, 20), const Offset(14.5, 20), const Offset(14.5, 18)], close: true);
        l(const Offset(12, 4), const Offset(12, 6));
        l(const Offset(9.5, 6), const Offset(14.5, 6));
        break;
      case 'settings':
        circle(const Offset(12, 12), 3.2);
        path([
          const Offset(12, 2.5), const Offset(13.5, 2.5), const Offset(14, 5),
          const Offset(16, 6), const Offset(18.3, 5.2), const Offset(19.5, 6.5),
          const Offset(18.7, 8.7), const Offset(19.7, 10.7), const Offset(22, 11.2),
          const Offset(22, 12.8), const Offset(19.7, 13.3), const Offset(18.7, 15.3),
          const Offset(19.5, 17.5), const Offset(18.3, 18.8), const Offset(16, 18),
          const Offset(14, 19), const Offset(13.5, 21.5), const Offset(10.5, 21.5),
          const Offset(10, 19), const Offset(8, 18), const Offset(5.7, 18.8),
          const Offset(4.5, 17.5), const Offset(5.3, 15.3), const Offset(4.3, 13.3),
          const Offset(2, 12.8), const Offset(2, 11.2), const Offset(4.3, 10.7),
          const Offset(5.3, 8.7), const Offset(4.5, 6.5), const Offset(5.7, 5.2),
          const Offset(8, 6), const Offset(10, 5), const Offset(10.5, 2.5),
        ], close: true);
        break;
      case 'search':
        circle(const Offset(11, 11), 6.5);
        l(const Offset(16, 16), const Offset(21, 21));
        break;
      case 'plus':
        l(const Offset(12, 5), const Offset(12, 19));
        l(const Offset(5, 12), const Offset(19, 12));
        break;
      case 'edit':
        path([const Offset(4, 20), const Offset(4, 16.5), const Offset(16, 4.5), const Offset(19.5, 8), const Offset(7.5, 20)], close: true);
        l(const Offset(14, 6.5), const Offset(17.5, 10));
        break;
      case 'trash':
        l(const Offset(4, 6), const Offset(20, 6));
        l(const Offset(9, 6), const Offset(9, 4));
        path([const Offset(6.5, 6), const Offset(7.3, 20), const Offset(16.7, 20), const Offset(17.5, 6)], close: true);
        l(const Offset(10, 10), const Offset(10, 16));
        l(const Offset(14, 10), const Offset(14, 16));
        break;
      case 'eye':
        path([const Offset(2.5, 12), const Offset(6, 7), const Offset(18, 7), const Offset(21.5, 12), const Offset(18, 17), const Offset(6, 17)], close: true);
        circle(const Offset(12, 12), 2.8);
        break;
      case 'check':
        l(const Offset(4.5, 12.5), const Offset(9.5, 17.5));
        l(const Offset(9.5, 17.5), const Offset(19.5, 6.5));
        break;
      case 'arrow':
        l(const Offset(4, 12), const Offset(20, 12));
        l(const Offset(14, 6), const Offset(20, 12));
        l(const Offset(14, 18), const Offset(20, 12));
        break;
      case 'menu':
        l(const Offset(3.5, 6.5), const Offset(20.5, 6.5));
        l(const Offset(3.5, 12), const Offset(20.5, 12));
        l(const Offset(3.5, 17.5), const Offset(20.5, 17.5));
        break;
      case 'logout':
        path([const Offset(9, 4), const Offset(4.5, 4), const Offset(4.5, 20), const Offset(9, 20)]);
        l(const Offset(14, 8), const Offset(20, 12));
        l(const Offset(14, 16), const Offset(20, 12));
        l(const Offset(20, 12), const Offset(9.5, 12));
        break;
      case 'sun':
        circle(const Offset(12, 12), 4);
        l(const Offset(12, 2.5), const Offset(12, 4.5));
        l(const Offset(12, 19.5), const Offset(12, 21.5));
        l(const Offset(2.5, 12), const Offset(4.5, 12));
        l(const Offset(19.5, 12), const Offset(21.5, 12));
        l(const Offset(5.3, 5.3), const Offset(6.7, 6.7));
        l(const Offset(17.3, 17.3), const Offset(18.7, 18.7));
        l(const Offset(18.7, 5.3), const Offset(17.3, 6.7));
        l(const Offset(6.7, 17.3), const Offset(5.3, 18.7));
        break;
      case 'moon':
        path([const Offset(20, 14.5), const Offset(19, 17), const Offset(16.5, 18.5), const Offset(14, 19)], close: false);
        path([
          const Offset(20, 14),
          const Offset(14.5, 19.5),
          const Offset(9, 19.5),
          const Offset(4.5, 15),
          const Offset(4.5, 9),
          const Offset(9, 4.5),
          const Offset(15, 4.5),
          const Offset(19.5, 9),
        ], close: true);
        break;
      case 'shield':
        path([const Offset(12, 3), const Offset(20, 6), const Offset(20, 12), const Offset(12, 21), const Offset(4, 12), const Offset(4, 6)], close: true);
        l(const Offset(9, 12), const Offset(11.3, 14.3));
        l(const Offset(11.3, 14.3), const Offset(15.5, 9.5));
        break;
      case 'heart':
        path([
          const Offset(12, 20),
          const Offset(4, 12.5),
          const Offset(4, 8),
          const Offset(7.5, 5),
          const Offset(12, 7),
          const Offset(16.5, 5),
          const Offset(20, 8),
          const Offset(20, 12.5),
        ], close: true);
        break;
      case 'copy':
        rect(9, 9, 11, 11, r: 2);
        path([const Offset(5, 15), const Offset(4, 15), const Offset(4, 4), const Offset(15, 4), const Offset(15, 5)]);
        break;
      default:
        rect(4, 4, 16, 16, r: 3);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.name != name || old.color != color;
}