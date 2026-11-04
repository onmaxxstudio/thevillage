import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Shared portrait compositor for the editor and member avatars.
class VillagePortrait extends StatelessWidget {
  const VillagePortrait({super.key, required this.skin, required this.hair,
    required this.hairColor, required this.face, required this.eyes,
    required this.smile, required this.presentation, required this.facialHair,
    required this.mole, required this.nose, required this.brows,
    required this.glasses, required this.freckles, required this.eyeColor,
    required this.outfit});
  final int skin, hair, hairColor, face, eyes, smile, presentation, facialHair,
      mole, nose, brows, glasses, freckles, eyeColor, outfit;

  static const skinTones = ['#3B2119','#563326','#704630','#81513D','#8B553A','#9C6045','#A66A4E','#B97855','#C98761','#D69A70','#E0AD86','#EDC29B'];
  static const hairTones = ['#171311','#2D211C','#542F23','#8A5837','#C17C36','#E1BE78','#4A4A47','#E1D9CC','#76509A','#B34E72'];
  static const shirts = ['#355C3B','#9E6257','#B5873F','#426A78','#72617E','#AD7654','#485D83','#855A74','#BD735D','#567663','#397778','#967241'];
  static const irises = ['#30231F','#79513B','#9A7A42','#52755B','#527B9B','#71818B'];

  static const assetDirectory = 'assets/avatar';
  static final _layers = <String, Future<ui.Image>>{};
  static final _program = ui.FragmentProgram.fromAsset('shaders/avatar_skin.frag');

  static Future<ui.Image> _load(String name) => _layers.putIfAbsent(name, () async {
    final data = await rootBundle.load('$assetDirectory/$name.webp');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  });

  static Widget starter(int index) => Image.asset(
    '$assetDirectory/starter_$index.webp',
    fit: BoxFit.contain,
  );

  Future<_PortraitArtwork> _loadArtwork() async {
    final layers = await Future.wait([
      _load('base_${presentation.clamp(0, 2)}'),
      if (hair < 10) _load('layer_${hair.clamp(0, 9)}'),
      if (facialHair >= 2) _load('layer_${facialHair == 4 ? 10 : 11}'),
    ]);
    return _PortraitArtwork(
      program: await _program,
      base: layers.first,
      hairstyle: hair < 10 ? layers[1] : null,
      beard: facialHair >= 2 ? layers.last : null,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_PortraitArtwork>(
    future: _loadArtwork(),
    builder: (context, snapshot) {
      final artwork = snapshot.data;
      if (artwork == null) return starter(presentation.clamp(0, 2));
      return RepaintBoundary(
        child: CustomPaint(painter: _PortraitPainter(this, artwork)),
      );
    },
  );
}

class _PortraitArtwork {
  const _PortraitArtwork({
    required this.program,
    required this.base,
    required this.hairstyle,
    required this.beard,
  });

  final ui.FragmentProgram program;
  final ui.Image base;
  final ui.Image? hairstyle;
  final ui.Image? beard;
}

class _PortraitPainter extends CustomPainter {
  const _PortraitPainter(this.look, this.artwork);

  final VillagePortrait look;
  final _PortraitArtwork artwork;

  static Color _color(List<String> palette, int index) =>
      Color(int.parse(palette[index.clamp(0, palette.length - 1)].substring(1), radix: 16) | 0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 512);
    _paintBase(canvas);
    _paintDetails(canvas);
    final beard = artwork.beard;
    if (beard != null) {
      canvas.save();
      if (look.facialHair == 2) {
        canvas.clipRect(const Rect.fromLTWH(0, 0, 512, 340));
      }
      _drawLayer(canvas, beard);
      canvas.restore();
    }
    final hairstyle = artwork.hairstyle;
    if (hairstyle != null) _drawLayer(canvas, hairstyle);
    canvas.restore();
  }

  void _paintBase(Canvas canvas) {
    final shader = artwork.program.fragmentShader();
    try {
      final skin = _color(VillagePortrait.skinTones, look.skin);
      final outfit = _color(VillagePortrait.shirts, look.outfit);
      final iris = _color(VillagePortrait.irises, look.eyeColor);
      final values = <double>[
        512, 512,
        skin.r / .65, skin.g / .39, skin.b / .27,
        (outfit.r - .24) * .36, (outfit.g - .24) * .36, (outfit.b - .24) * .36,
        (iris.r - .19) * .45, (iris.g - .14) * .45, (iris.b - .12) * .45,
        const [0.0, .35, -.38][look.face.clamp(0, 2)],
        const [0.0, -.55, .65][look.eyes.clamp(0, 2)],
        const [0.0, -.058, .068][look.smile.clamp(0, 2)],
        const [0.0, .46, -.65][look.nose.clamp(0, 2)],
        const [0.0, -.75, .66][look.brows.clamp(0, 2)],
        look.presentation.toDouble(),
      ];
      for (var i = 0; i < values.length; i++) {
        shader.setFloat(i, values[i]);
      }
      shader.setImageSampler(0, artwork.base);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 512, 512), Paint()..shader = shader);
    } finally {
      shader.dispose();
    }
  }

  void _drawLayer(Canvas canvas, ui.Image image) {
    final color = _color(VillagePortrait.hairTones, look.hairColor);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (look.hairColor != 0) {
      paint.colorFilter = ColorFilter.matrix([
        1, 0, 0, 0, (color.r * 255 - 23) * .77,
        0, 1, 0, 0, (color.g * 255 - 19) * .77,
        0, 0, 1, 0, (color.b * 255 - 17) * .77,
        0, 0, 0, 1, 0,
      ]);
    }
    canvas.drawImage(image, Offset.zero, paint);
  }

  void _paintDetails(Canvas canvas) {
    final eyeY = look.presentation == 1 ? 247.0 : 255.0;
    final mark = Paint()..color = const Color(0x9A4A251D);
    if (look.freckles > 0) {
      for (var i = 0; i < (look.freckles == 1 ? 8 : 20); i++) {
        final x = 201.0 + (i * 23 % 108);
        final y = eyeY + 24 + (i * 11 % 15);
        canvas.drawCircle(Offset(x, y), 1.4 + (i % 3) * .35, mark);
      }
    }
    if (look.mole == 1 || look.mole == 4) {
      canvas.drawCircle(Offset(209, eyeY + 52), 3.3, mark);
    }
    if (look.mole == 2 || look.mole == 4) {
      canvas.drawCircle(Offset(304, eyeY + 49), 3.3, mark);
    }
    if (look.mole == 3) canvas.drawCircle(Offset(262, eyeY + 105), 3.3, mark);

    if (look.facialHair == 1) {
      final stubble = Paint()..color = const Color(0x8840271C);
      for (var i = 0; i < 156; i++) {
        final x = 196.0 + (i * 29 % 121);
        final width = (x - 256).abs() / 60;
        final y = eyeY + 99 - width * width * 32 + (i * 13 % 23);
        canvas.drawCircle(Offset(x, y), 1.1, stubble);
      }
    }
    if (look.glasses > 0) {
      final frame = Paint()
        ..color = const Color(0xFF332B27)
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke;
      final radius = Radius.circular(look.glasses == 1 ? 10 : 22);
      for (final x in [215.0, 297.0]) {
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, eyeY + 1), width: 67, height: 50),
          radius,
        ), frame);
      }
      canvas.drawPath(Path()
        ..moveTo(248, eyeY)
        ..quadraticBezierTo(256, eyeY - 8, 264, eyeY), frame);
    }
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      oldDelegate.look != look || oldDelegate.artwork != artwork;
}
