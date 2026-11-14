import 'package:flutter/material.dart';
import 'village_plus_photo.dart';
import '../screens/village_plus_screen.dart';

const _forest = Color(0xFF073C24);
const _gold = Color(0xFFE8C575);

class VillagePlusBanner extends StatelessWidget {
  const VillagePlusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _forest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: const Color(0x400D3020),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VillagePlusScreen()),
        ),
        child: Stack(
          children: [
            // The original content remains the size authority at every width
            // and text scale. The new artwork cannot expand the homepage.
            const ExcludeSemantics(
              child: IgnorePointer(
                child: Opacity(opacity: 0, child: _BannerFootprint()),
              ),
            ),
            Positioned.fill(child: _BannerArtwork()),
          ],
        ),
      ),
    );
  }
}

class _BannerArtwork extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact =
          box.maxWidth < 396 || MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final features = box.maxWidth >= 700 && !compact;
      final desktop = box.maxWidth >= 950;
      final photoWidth = compact
          ? 115.0
          : (features ? (desktop ? 135.0 : 88.0) : 85.0);
      final title = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF7DEA0), Color(0xFFC69942)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: _forest,
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Village Plus',
              style: TextStyle(
                fontFamily: 'VillagePlusDisplay',
                color: Colors.white,
                fontSize: desktop ? 37 : 30,
                height: 1.16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 5),
          if (!compact)
            const Text(
              'Deeper support. Exclusive tools. Monthly workshops. And more.',
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
            ),
        ],
      );
      final price = FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$4.99',
              style: TextStyle(
                fontFamily: 'VillagePlusDisplay',
                color: _gold,
                fontSize: desktop ? 36 : 30,
                height: 1.12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              '/month',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      );
      const arrow = CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(Icons.arrow_forward_rounded, color: _forest, size: 23),
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF234E31),
                      Color(0xFF07351F),
                      Color(0xFF092C1C),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              top: compact ? null : 0,
              width: photoWidth,
              height: compact ? 115 : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const VillagePlusPhoto(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x0007351F),
                          Color(0x0007351F),
                          Color(0xFF103B25),
                        ],
                        stops: [0, .65, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _GoldAccent())),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : photoWidth + 6,
                12,
                16,
                14,
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 8),
                        const Text(
                          'Deeper support. Exclusive tools.\nMonthly workshops. And more.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Spacer(),
                            Flexible(flex: 2, child: price),
                            const SizedBox(width: 16),
                            arrow,
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: desktop ? 5 : 4, child: title),
                        if (features) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: desktop ? 6 : 5,
                            child: _FeatureStrip(desktop: desktop),
                          ),
                        ],
                        Container(
                          width: 1,
                          height: 72,
                          margin: EdgeInsets.symmetric(
                            horizontal: desktop ? 18 : 12,
                          ),
                          color: _gold.withValues(alpha: .65),
                        ),
                        SizedBox(width: desktop ? 90 : 73, child: price),
                        const SizedBox(width: 12),
                        arrow,
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({required this.desktop});
  final bool desktop;
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.spa_outlined, 'Growth\nTools'),
      (Icons.calendar_month_outlined, 'Monthly\nEvents'),
      (Icons.people_alt_outlined, 'Deeper\nJourneys'),
      (Icons.trending_up_rounded, 'Track Your\nProgress'),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Container(width: 1, height: 62, color: _gold.withValues(alpha: .6)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$1, color: _gold, size: desktop ? 28 : 24),
                const SizedBox(height: 6),
                Text(
                  items[i].$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: desktop ? 12 : 10.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GoldAccent extends CustomPainter {
  const _GoldAccent();
  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(size.width * .32, size.height - 5)
      ..cubicTo(
        size.width * .53,
        size.height + 15,
        size.width * .64,
        size.height - 31,
        size.width * .79,
        size.height - 12,
      )
      ..quadraticBezierTo(
        size.width * .9,
        size.height + 4,
        size.width,
        size.height - 3,
      );
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = const LinearGradient(
          colors: [Color(0x007B6028), _gold, Color(0x338E6F2D)],
        ).createShader(Offset.zero & size),
    );
    final leaf = Paint()..color = _gold.withValues(alpha: .55);
    final x = size.width * .47;
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(x + i * 7, 17 - i * 2);
      canvas.rotate(-.65);
      canvas.drawOval(const Rect.fromLTWH(0, 0, 4, 9), leaf);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GoldAccent oldDelegate) => false;
}

// Layout-only copy of the pre-redesign banner. Never paint or expose this in
// accessibility: it preserves the exact original intrinsic height, including
// wrapping and the existing 360px inner-width / 1.3x text-scale breakpoints.
class _BannerFootprint extends StatelessWidget {
  const _BannerFootprint();
  @override
  Widget build(BuildContext context) {
    const forest = _forest;
    const gold = Color(0xFFF5CB62);
    Widget metricText(String value, {required TextStyle style}) => RichText(
      text: TextSpan(
        text: value,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textScaler: MediaQuery.textScalerOf(context),
    );
    return Padding(
      padding: EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final description = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: metricText(
                  'NEW',
                  style: TextStyle(
                    color: forest,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 6),
              metricText(
                'Village Plus',
                style: TextStyle(
                  fontFamily: 'VillagePlusDisplay',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 27 : 32,
                ),
              ),
              SizedBox(height: 7),
              metricText(
                'Deeper support. Exclusive tools.\nMonthly workshop. And more.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          );
          final price = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              metricText(
                '\$4.99',
                style: TextStyle(
                  color: gold,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              metricText(
                '/month',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          );
          final arrow = CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(Icons.arrow_forward_rounded, color: forest, size: 23),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                description,
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: gold, height: 1),
                ),
                Row(
                  children: [
                    Expanded(child: price),
                    SizedBox(width: 12),
                    arrow,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: description),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 18),
                width: 1,
                height: 72,
                color: gold,
              ),
              price,
              SizedBox(width: 16),
              arrow,
            ],
          );
        },
      ),
    );
  }
}
