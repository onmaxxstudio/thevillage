import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

/// Shared portrait compositor for the editor and member avatars.
class VillagePortrait extends StatelessWidget {
  const VillagePortrait({
    super.key,
    required this.skin,
    required this.hair,
    required this.hairColor,
    required this.face,
    required this.eyes,
    required this.smile,
    required this.presentation,
    required this.facialHair,
    required this.mole,
    required this.nose,
    required this.brows,
    required this.glasses,
    required this.freckles,
    required this.eyeColor,
    required this.outfit,
  });
  final int skin,
      hair,
      hairColor,
      face,
      eyes,
      smile,
      presentation,
      facialHair,
      mole,
      nose,
      brows,
      glasses,
      freckles,
      eyeColor,
      outfit;

  static const skinTones = [
    '#3B2119',
    '#563326',
    '#704630',
    '#81513D',
    '#8B553A',
    '#9C6045',
    '#A66A4E',
    '#B97855',
    '#C98761',
    '#D69A70',
    '#E0AD86',
    '#EDC29B',
    '#EAC8B5',
    '#F3D9CA',
    '#FBC19F',
  ];
  static const hairTones = [
    '#171311',
    '#2D211C',
    '#542F23',
    '#8A5837',
    '#C17C36',
    '#E1BE78',
    '#B8BAC1',
    '#F3F2EE',
    '#76509A',
    '#B34E72',
  ];
  static const shirts = [
    '#355C3B',
    '#9E6257',
    '#B5873F',
    '#426A78',
    '#72617E',
    '#AD7654',
    '#485D83',
    '#855A74',
    '#BD735D',
    '#567663',
    '#397778',
    '#967241',
  ];
  static const irises = [
    '#30231F',
    '#79513B',
    '#9A7A42',
    '#52755B',
    '#527B9B',
    '#71818B',
  ];

  static const assetDirectory = 'assets/avatar';
  static final _layers = <String, Future<ui.Image>>{};
  static final _basePixels = <int, Future<Uint8List>>{};
  static final _bases =
      <(int, int, int, int, int, int, int, int, int), Future<ui.Image>>{};
  static const _resolution = 384;

  Future<ui.Image> _loadBase() {
    final base = presentation.clamp(0, 2);
    final key = (base, skin, outfit, eyeColor, face, eyes, smile, nose, brows);
    final cached = _bases.remove(key);
    if (cached != null) {
      _bases[key] = cached;
      return cached;
    }
    if (_bases.length >= 32) _bases.remove(_bases.keys.first);
    return _bases[key] = _renderBase(base);
  }

  // Bake a regular image instead of sampling the base texture in a fragment
  // shader. Safari can then paint it through the same path as the hair sprites.
  Future<ui.Image> _renderBase(int base) async {
    const size = _resolution;
    final source = await _basePixels.putIfAbsent(base, () async {
      final data = await rootBundle.load('$assetDirectory/base_$base.webp');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: size,
        targetHeight: size,
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          final pixels = (await frame.image.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          ))!;
          return pixels.buffer.asUint8List(
            pixels.offsetInBytes,
            pixels.lengthInBytes,
          );
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    });
    final output = Uint8List(source.length);
    final tone = _PortraitPainter._color(skinTones, skin);
    final shirt = _PortraitPainter._color(shirts, outfit);
    final iris = _PortraitPainter._color(irises, eyeColor);
    final faceWarp = const [0.0, .16, -.18][face.clamp(0, 2)];
    final eyeWarp = const [0.0, -.55, .65][eyes.clamp(0, 2)];
    final cornerLift = const [0.0, .024, -.017][smile.clamp(0, 2)];
    final noseWarp = const [0.0, .46, -.65][nose.clamp(0, 2)];
    final browWarp = const [0.0, -.75, .66][brows.clamp(0, 2)];
    final eyeY = base == 1 ? .482 : .498;

    for (var row = 0; row < size; row++) {
      final y = (row + .5) / size;
      final clothing = _smooth(.72, .82, y);
      for (var col = 0; col < size; col++) {
        final x = (col + .5) / size;
        final eyeX = x < .5 ? .421 : .579;
        var qx = x;
        var qy = y;
        if (faceWarp != 0) {
          // Shape the cheeks and jaw without rescaling the eyes, nose, or lips.
          final contour = _smooth(.075, .17, (x - .5).abs());
          qx += (x - .5) * faceWarp * contour *
              _region(x - .5, y - .61, .27, .20);
          qy -= faceWarp * .10 * _region(x - .5, y - .715, .16, .053);
        }
        if (eyeWarp != 0) {
          qy += (y - eyeY) * eyeWarp * _region(x - eyeX, y - eyeY, .081, .052);
        }
        if (cornerLift != 0) {
          final mouthX = x - .5;
          final mouthY = y - eyeY - .169;
          // Lift and widen the smile while keeping the center of the lips steady.
          final falloff = _region(mouthX, mouthY, .121, .052);
          final cornerWeight = _smooth(.015, .072, mouthX.abs());
          qy += cornerLift * cornerWeight * falloff;
          qx -= mouthX * cornerLift * 7 * falloff;
        }
        if (noseWarp != 0) {
          qx +=
              (x - .5) *
              noseWarp *
              _region(x - .5, y - eyeY - .103, .105, .067);
        }
        if (browWarp != 0) {
          qy +=
              (y - eyeY + .065) *
              browWarp *
              _region(x - eyeX, y - eyeY + .065, .08, .04);
        }
        final from =
            ((qy * size).floor().clamp(0, size - 1) * size +
                (qx * size).floor().clamp(0, size - 1)) *
            4;
        final alpha = source[from + 3];
        if (alpha == 0) continue;
        final r = source[from] / 255;
        final g = source[from + 1] / 255;
        final b = source[from + 2] / 255;
        final isFair = skin >= 12;
        final warm = isFair
            ? _smooth(.035, .14, r - b) * _smooth(.018, .078, r - g)
            : _smooth(.03, .16, r - b) * _smooth(.01, .10, r - g);
        final fabric = clothing * (1 - warm) * .36;
        // Preserve the base's sculpted shadows while softening the
        // contrast of the warm source artwork for fair complexions.
        final light = (r * .30 + g * .59 + b * .11 - .48) * .45;
        final tintedRed = isFair
            ? r + (tone.r + light - r) * warm
            : r * (1 + (tone.r / .65 - 1) * warm);
        final tintedGreen = isFair
            ? g + (tone.g + light - g) * warm
            : g * (1 + (tone.g / .39 - 1) * warm);
        final tintedBlue = isFair
            ? b + (tone.b + light - b) * warm
            : b * (1 + (tone.b / .27 - 1) * warm);
        final irisWeight =
            _region(qx - eyeX, qy - eyeY, .025, .029) *
            _smooth(.05, .19, tintedRed) *
            .45;
        final to = (row * size + col) * 4;
        // decodeImageFromPixels expects premultiplied RGBA.
        output[to] =
            ((tintedRed +
                            fabric * (shirt.r - .24) +
                            irisWeight * (iris.r - .19))
                        .clamp(0.0, 1.0) *
                    alpha)
                .round();
        output[to + 1] =
            ((tintedGreen +
                            fabric * (shirt.g - .24) +
                            irisWeight * (iris.g - .14))
                        .clamp(0.0, 1.0) *
                    alpha)
                .round();
        output[to + 2] =
            ((tintedBlue +
                            fabric * (shirt.b - .24) +
                            irisWeight * (iris.b - .12))
                        .clamp(0.0, 1.0) *
                    alpha)
                .round();
        output[to + 3] = alpha;
      }
    }
    final decoded = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      output,
      size,
      size,
      ui.PixelFormat.rgba8888,
      decoded.complete,
    );
    return decoded.future;
  }

  static double _smooth(double start, double end, double value) {
    final t = ((value - start) / (end - start)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static double _region(double x, double y, double width, double height) {
    final dx = x / width;
    final dy = y / height;
    final distance = dx * dx + dy * dy;
    return distance >= 1 ? 0 : 1 - _smooth(.12, 1, math.sqrt(distance));
  }

  static Future<ui.Image> _load(String name) =>
      _layers.putIfAbsent(name, () async {
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

  static Widget starter(int index) =>
      Image.asset('$assetDirectory/starter_$index.webp', fit: BoxFit.contain);

  Future<_PortraitArtwork> _loadArtwork() async {
    final hasHair = hair >= 0 && hair <= 16 && hair != 10;
    // Sprite slots 10 and 11 are facial hair. Bald stays at hairstyle ID 10.
    final hairLayer = hair < 10 ? hair : hair + 1;
    final layers = await Future.wait([
      _loadBase(),
      if (hasHair) _load('layer_$hairLayer'),
      if (facialHair >= 2) _load('layer_${facialHair == 4 ? 10 : 11}'),
    ]);
    return _PortraitArtwork(
      base: layers.first,
      hairstyle: hasHair ? layers[1] : null,
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
    required this.base,
    required this.hairstyle,
    required this.beard,
  });

  final ui.Image base;
  final ui.Image? hairstyle;
  final ui.Image? beard;
}

class _PortraitPainter extends CustomPainter {
  const _PortraitPainter(this.look, this.artwork);

  final VillagePortrait look;
  final _PortraitArtwork artwork;

  static Color _color(List<String> palette, int index) => Color(
    int.parse(
          palette[index.clamp(0, palette.length - 1)].substring(1),
          radix: 16,
        ) |
        0xFF000000,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 512);
    canvas.drawImageRect(
      artwork.base,
      Rect.fromLTWH(
        0,
        0,
        artwork.base.width.toDouble(),
        artwork.base.height.toDouble(),
      ),
      const Rect.fromLTWH(0, 0, 512, 512),
      Paint()..filterQuality = FilterQuality.medium,
    );
    _paintDetails(canvas);
    final beard = artwork.beard;
    if (beard != null) {
      final masculine = look.presentation == 1;
      final jawWidth = switch (look.face) {
        1 => .96,
        2 => 1.04,
        _ => 1.0,
      };
      canvas.save();
      if (look.facialHair == 4) {
        // Keep the moustache anchored while fitting the beard to the jaw.
        canvas.translate(256, masculine ? 311 : 317);
        canvas.scale((masculine ? .89 : .81) * jawWidth, .86);
        canvas.translate(-256, -320);
        _drawLayer(canvas, beard);
      } else {
        final mouthOffset = masculine ? 0.0 : 8.0;
        _drawLayer(
          canvas,
          beard,
          source: const Rect.fromLTRB(165, 308, 350, 370),
          destination: Rect.fromCenter(
            center: Offset(256, 306 + mouthOffset),
            width: 92 * jawWidth,
            height: 22,
          ),
        );
        if (look.facialHair == 3) {
          _drawLayer(
            canvas,
            beard,
            source: const Rect.fromLTRB(185, 380, 331, 468),
            destination: Rect.fromCenter(
              center: Offset(256, 348 + mouthOffset),
              width: 66 * jawWidth,
              height: 33,
            ),
          );
        }
      }
      canvas.restore();
    }
    final hairstyle = artwork.hairstyle;
    if (hairstyle != null) {
      // Anchor the fitted sprites at the center of the hairline so narrowing
      // the sides does not shift the part or lift the fringe off the forehead.
      final width = switch (look.hair) {
        0 => .88, // Afro
        1 => .98, // Locs
        2 => .97, // Twists
        3 => .98, // Braids
        4 => .82, // Bantu knots
        5 => .94, // Curls
        6 => .75, // Waves
        7 => .84, // Short crop
        8 => .96, // Bun
        9 => .96, // Ponytail
        11 => .97, // Straight bob
        12 => .96, // Side part
        _ => 1.0,
      };
      final scalpWidth = switch (look.face) {
        1 => .97, // Long
        2 => 1.035, // Round
        _ => 1.0,
      };
      final presentationWidth = look.presentation == 1 ? 1.035 : 1.0;
      // The Afro sprite's forehead opening starts near y=190. Scale
      // around it to bring the crown and lower edges closer to the head.
      final isAfro = look.hair == 0;
      final hairlineY = isAfro ? 190.0 : 0.0;
      final presentationOffset = look.presentation == 1 ? -5.0 : 0.0;
      canvas.save();
      canvas.translate(256, hairlineY + presentationOffset);
      canvas.scale(width * scalpWidth * presentationWidth, isAfro ? .87 : 1);
      canvas.translate(-256, -hairlineY);
      _drawLayer(canvas, hairstyle);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawLayer(
    Canvas canvas,
    ui.Image image, {
    Rect? source,
    Rect? destination,
  }) {
    final color = _color(VillagePortrait.hairTones, look.hairColor);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (look.hairColor == 6 || look.hairColor == 7) {
      // Map the source highlights and shadows into a lighter tonal range.
      final white = look.hairColor == 7;
      final contrast = white ? 1.3 : 1.65;
      final red = .213 * contrast;
      final green = .715 * contrast;
      final blue = .072 * contrast;
      paint.colorFilter = ColorFilter.matrix([
        red, green, blue, 0, white ? 188 : 132,
        red, green, blue, 0, white ? 187 : 134,
        red, green, blue, 0, white ? 183 : 141,
        0, 0, 0, 1, 0,
      ]);
    } else if (look.hairColor != 0) {
      paint.colorFilter = ColorFilter.matrix([
        1,
        0,
        0,
        0,
        (color.r * 255 - 23) * .77,
        0,
        1,
        0,
        0,
        (color.g * 255 - 19) * .77,
        0,
        0,
        1,
        0,
        (color.b * 255 - 17) * .77,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    if (source != null && destination != null) {
      canvas.drawImageRect(image, source, destination, paint);
    } else {
      canvas.drawImage(image, Offset.zero, paint);
    }
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
      final paint = Paint();
      final color = _color(VillagePortrait.hairTones, look.hairColor);
      // A fixed seed keeps the texture stable when the portrait repaints.
      final random = math.Random(72);
      final width = look.presentation == 1 ? 76.0 : 68.0;
      for (var i = 0; i < 920; i++) {
        final side = random.nextDouble() * 2 - 1;
        final depth = random.nextDouble();
        final edge = side.abs();
        final top = eyeY + 82 - edge * edge * 32;
        final bottom = eyeY + 113 - edge * edge * 38;
        final fade = (1 - (depth * 2 - 1).abs()) * (1 - edge * edge);
        paint.color = color.withValues(alpha: .10 + .24 * fade);
        canvas.drawCircle(
          Offset(256 + side * width, top + (bottom - top) * depth),
          .34 + random.nextDouble() * .43,
          paint,
        );
      }
    }
    if (look.glasses > 0) {
      final frame = Paint()
        ..color = const Color(0xFF332B27)
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke;
      final radius = Radius.circular(look.glasses == 1 ? 10 : 22);
      for (final x in [215.0, 297.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, eyeY + 1), width: 67, height: 50),
            radius,
          ),
          frame,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(248, eyeY)
          ..quadraticBezierTo(256, eyeY - 8, 264, eyeY),
        frame,
      );
    }
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      oldDelegate.look != look || oldDelegate.artwork != artwork;
}
