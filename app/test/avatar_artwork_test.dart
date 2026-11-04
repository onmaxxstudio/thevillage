import 'dart:ui' as ui;

import 'package:flutter/services.dart';
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
}
