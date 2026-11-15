import 'package:flutter/material.dart';

/// Gives the phone planner the compact proportions of the approved overview.
/// Larger accessibility text keeps its normal, scrollable layout.
class PlannerViewport extends StatelessWidget {
  const PlannerViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final media = MediaQuery.of(context);
      if (constraints.maxWidth >= 600 ||
          media.textScaler.scale(1) > 1.3) {
        return child;
      }
      const scale = .85;
      final size = Size(
        constraints.maxWidth / scale,
        constraints.maxHeight / scale,
      );
      return FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        child: SizedBox.fromSize(
          size: size,
          child: MediaQuery(
            data: media.copyWith(
              size: size,
              padding: media.padding / scale,
              viewPadding: media.viewPadding / scale,
              viewInsets: media.viewInsets / scale,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}
