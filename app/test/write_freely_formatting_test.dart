import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ask_the_village/screens/write_freely_screen.dart';

void main() {
  testWidgets('saved journal content preserves bold, italic, links, and bullets',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: JournalFormattedBody(
          body: '**Bold words** and _gentle words_ with [a link](https://example.com)\n• A list item',
        ),
      ),
    ));

    final richText = tester.widgetList<RichText>(find.byType(RichText)).toList();
    expect(richText, hasLength(2));
    final formattedSpans = (richText.first.text as TextSpan).children!;
    expect(formattedSpans.any((span) =>
        span is TextSpan &&
        span.text == 'Bold words' &&
        span.style?.fontWeight == FontWeight.w700), isTrue);
    expect(formattedSpans.any((span) =>
        span is TextSpan &&
        span.text == 'gentle words' &&
        span.style?.fontStyle == FontStyle.italic), isTrue);
    expect(formattedSpans.any((span) =>
        span is TextSpan &&
        span.text == 'a link' &&
        span.recognizer != null), isTrue);
    expect(find.text('•  '), findsOneWidget);
    expect(find.text('A list item'), findsOneWidget);
  });
}
