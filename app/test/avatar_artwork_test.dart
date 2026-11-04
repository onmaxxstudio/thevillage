import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../lib/widgets/village_portrait.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all portrait sprites decode at the compositor resolution', () async {
    final names = [
      for (var i = 0; i < 3; i++) ...['base_$i', 'starter_$i'],
      for (var i = 0; i < 12; i++) 'layer_$i',
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

  test('portrait shader can be loaded from the Flutter asset bundle', () async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/avatar_skin.frag',
    );
    program.fragmentShader().dispose();
  });

  testWidgets('every appearance field changes the painted portrait', (
    tester,
  ) async {
    final frameKey = GlobalKey();
    final fields = <String, int>{
      'skin': 12,
      'hair': 11,
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

    Future<Uint8List> render(String field, int value) async {
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
                  key: ValueKey((field, value)),
                  skin: option('skin', 5),
                  hair: option('hair'),
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
