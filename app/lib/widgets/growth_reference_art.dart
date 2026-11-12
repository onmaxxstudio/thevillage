import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays unaltered artwork regions from the owner's approved reference.
/// Text and data elsewhere in Growth Studio remain native, interactive widgets.
class GrowthReferenceArt extends StatelessWidget {
  const GrowthReferenceArt({super.key, required this.region, this.label});
  final Rect region;
  final String? label;
  static final Future<ui.Image> _image = _load();
  static Future<ui.Image> _load() async {
    final bytes = await rootBundle.load('assets/images/growth_reference.jpg');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    excludeSemantics: true,
    child: AspectRatio(
      aspectRatio: region.width / region.height,
      child: FutureBuilder<ui.Image>(
        future: _image,
        builder: (context, snapshot) => snapshot.hasData
            ? CustomPaint(painter: _ReferencePainter(snapshot.data!, region))
            : const SizedBox.expand(),
      ),
    ),
  );
}

class _ReferencePainter extends CustomPainter {
  const _ReferencePainter(this.image, this.region);
  final ui.Image image;
  final Rect region;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    image,
    region,
    Offset.zero & size,
    Paint()..filterQuality = FilterQuality.high,
  );
  @override
  bool shouldRepaint(_ReferencePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.region != region;
}

/// A shared botanical sprig for the header and membership price ornaments.
class GrowthLeafSprig extends StatelessWidget {
  const GrowthLeafSprig({super.key, this.mirrored = false});
  final bool mirrored;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: Transform.flip(
    flipX: mirrored, child: const SizedBox(width: 56, height: 26,
      child: CustomPaint(painter: _SprigPainter()))));
}

class _SprigPainter extends CustomPainter {
  const _SprigPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();canvas.scale(size.width / 56, size.height / 26);
    final stem = Paint()..color = const Color(0xFF849050)..strokeWidth = 1.1..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(2,20)..quadraticBezierTo(27,10,53,12), stem);
    final leaf = Paint()..color = const Color(0xFF899454);
    for(final spec in const [(10.0,17.0,-.9),(21.0,13.0,-1.1),(34.0,11.0,-.95),
      (19.0,15.0,.65),(32.0,12.0,.7),(45.0,12.0,.55)]) {
      canvas.save();canvas.translate(spec.$1,spec.$2);canvas.rotate(spec.$3);
      canvas.drawPath(Path()..moveTo(0,0)..quadraticBezierTo(4,-6,12,0)
        ..quadraticBezierTo(5,5,0,0)..close(),leaf);canvas.restore();
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(_SprigPainter oldDelegate) => false;
}
