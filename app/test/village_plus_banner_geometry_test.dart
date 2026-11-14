import 'package:ask_the_village/widgets/village_plus_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures/original_village_plus_banner.dart';

void main() {
  for (final width in [
    280.0,
    320.0,
    390.0,
    431.0,
    432.0,
    600.0,
    735.0,
    736.0,
    768.0,
    1024.0,
    1100.0,
    1440.0,
  ]) {
    for (final scale in [1.0, 1.3, 1.31, 2.0]) {
      testWidgets('Preserves original banner geometry at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<(Size, Offset)> measure(Widget banner) async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        SizedBox(key: const ValueKey('banner'), child: banner),
                        const SizedBox(height: 14),
                        const SizedBox(key: ValueKey('next'), height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          return (
            tester.getSize(find.byKey(const ValueKey('banner'))),
            tester.getTopLeft(find.byKey(const ValueKey('next'))),
          );
        }

        final before = await measure(const OriginalVillagePlusBanner());
        final after = await measure(const VillagePlusBanner());
        expect(
          after,
          before,
          reason: 'Banner and all following content must retain exact geometry',
        );
      });
    }
  }
}
