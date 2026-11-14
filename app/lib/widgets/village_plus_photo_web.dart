import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// A native image also works in browsers running CanvasKit without WebGL.
// No pointer events: the existing banner InkWell owns the entire tap target.
class VillagePlusPhoto extends StatelessWidget {
  const VillagePlusPhoto({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: HtmlElementView.fromTagName(
      tagName: 'img',
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      onElementCreated: (element) {
        final image = _BannerImage(element as JSObject);
        image.src = 'assets/assets/images/village_plus_cozy.webp';
        image.alt = '';
        image.style
          ..width = '100%'
          ..height = '100%'
          ..objectFit = 'cover'
          ..objectPosition = 'left center'
          ..pointerEvents = 'none';
      },
    ),
  );
}

extension type _BannerImage(JSObject _) implements JSObject {
  external set src(String value);
  external set alt(String value);
  external _BannerStyle get style;
}
extension type _BannerStyle(JSObject _) implements JSObject {
  external set width(String value);
  external set height(String value);
  external set objectFit(String value);
  external set objectPosition(String value);
  external set pointerEvents(String value);
}
