import 'dart:js_interop';

@JS('window.screen.width')
external JSNumber get _screenWidth;

@JS('window.screen.height')
external JSNumber get _screenHeight;

@JS('window.innerWidth')
external JSNumber get _innerWidth;

@JS('window.innerHeight')
external JSNumber get _innerHeight;

/// Screen CSS dimensions remain stable when Safari changes page zoom.
/// Use the long edge in landscape, and leave desktop layouts responsive.
double? phoneBrowserWidth() {
  final shortEdge = _screenWidth.toDartDouble < _screenHeight.toDartDouble
      ? _screenWidth.toDartDouble
      : _screenHeight.toDartDouble;
  if (shortEdge > 600) return null;
  return _innerWidth.toDartDouble > _innerHeight.toDartDouble
      ? (_screenWidth.toDartDouble > _screenHeight.toDartDouble
            ? _screenWidth.toDartDouble
            : _screenHeight.toDartDouble)
      : shortEdge;
}
