import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ask_the_village/widgets/planner_viewport.dart';

void main() {
  testWidgets('community phone canvas fits the approved compact proportions', (tester) async {
    tester.view.physicalSize = const Size(393, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Size canvas;
    await tester.pumpWidget(MaterialApp(home: PlannerViewport(
      scale: .75,
      child: Builder(builder: (context) {
        canvas = MediaQuery.sizeOf(context);
        return const SizedBox.expand();
      }),
    )));
    expect(canvas.width, 524);
    expect(canvas.height, 1000);
    expect(tester.takeException(), isNull);
  });
}
