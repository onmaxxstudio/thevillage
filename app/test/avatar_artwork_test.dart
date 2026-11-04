import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:ask_the_village/widgets/village_portrait.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all portrait sprites decode at the compositor resolution', () async {
    final names = [
      for (var i = 0; i < 3; i++) ...['base_$i', 'starter_$i'],
      for (var i = 0; i < 15; i++) 'layer_$i',
    ];
    for (final name in names) {
      final data = await rootBundle.load('assets/avatar/$name.webp');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 512, reason: name);
      expect(frame.image.height, 512, reason: name);
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets('every appearance field changes the painted portrait', (
    tester,
  ) async {
    final frameKey = GlobalKey();
    final fields = <String, int>{
      'skin': 12,
      'hair': 14,
      'hairColor': 10,
      'face': 3,
      'eyes': 3,
      'smile': 3,
      'presentation': 3,
      'facialHair': 5,
      'mole': 5,
      'nose': 3,
      'brows': 3,
      'glasses': 3,
      'freckles': 3,
      'eyeColor': 6,
      'outfit': 12,
    };

    Future<Uint8List> render(
      String field,
      int value, {
      bool bald = false,
    }) async {
      int option(String name, [int initial = 0]) =>
          name == field ? value : initial;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: frameKey,
              child: SizedBox.square(
                dimension: 256,
                child: VillagePortrait(
                  key: ValueKey((field, value, bald)),
                  skin: option('skin', 5),
                  hair: bald ? 10 : option('hair'),
                  hairColor: option('hairColor'),
                  face: option('face'),
                  eyes: option('eyes'),
                  smile: option('smile'),
                  presentation: option('presentation'),
                  facialHair: option('facialHair'),
                  mole: option('mole'),
                  nose: option('nose'),
                  brows: option('brows'),
                  glasses: option('glasses'),
                  freckles: option('freckles'),
                  eyeColor: option('eyeColor'),
                  outfit: option('outfit'),
                ),
              ),
            ),
          ),
        ),
      );
      final portrait = find.byType(VillagePortrait);
      final paint = find.descendant(
        of: portrait,
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter != null,
        ),
      );
      for (
        var attempts = 0;
        attempts < 80 && paint.evaluate().isEmpty;
        attempts++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 15)),
        );
        await tester.pump();
      }
      expect(paint, findsOneWidget, reason: '$field=$value');
      final image = await tester.runAsync(
        () =>
            (frameKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(),
      );
      try {
        final bytes = await tester.runAsync(() => image!.toByteData());
        return bytes!.buffer.asUint8List();
      } finally {
        image!.dispose();
      }
    }

    for (var presentation = 0; presentation < 3; presentation++) {
      final pixels = await render('presentation', presentation, bald: true);
      for (final row in [139, 218]) {
        expect(
          pixels[(row * 256 + 128) * 4 + 3],
          greaterThan(240),
          reason:
              'Presentation $presentation must paint its face and shoulders',
        );
      }
    }

    for (final entry in fields.entries) {
      final variants = <Uint8List>[];
      for (var value = 0; value < entry.value; value++) {
        final next = await render(entry.key, value);
        expect(
          variants.any((prior) => listEquals(prior, next)),
          isFalse,
          reason: '${entry.key} variant $value must produce different pixels',
        );
        variants.add(next);
      }
    }
  });
}
