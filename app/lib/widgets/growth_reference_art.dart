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
