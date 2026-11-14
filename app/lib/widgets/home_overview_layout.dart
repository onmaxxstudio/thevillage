import 'package:flutter/material.dart';

/// Keeps the phone overview in the horizontal arrangement used on tablets.
/// Only this dashboard is scaled; routes opened from it use normal device size.
class HomeOverviewLayout extends StatelessWidget {
  const HomeOverviewLayout({
    super.key,
    required this.header,
    required this.sections,
  });

  final Widget header;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) {
        final media = MediaQuery.of(context);
        final compactOverview =
            viewport.maxWidth < 600 && media.textScaler.scale(1) <= 1.3;
        final width = compactOverview
            ? 768.0
            : viewport.maxWidth.clamp(0.0, 1100.0);
        final scale = compactOverview ? viewport.maxWidth / width : 1.0;
        final content = MediaQuery(
          data: media.copyWith(
            size: Size(width, media.size.height / scale),
            textScaler: TextScaler.linear(media.textScaler.scale(1) * 1.12),
          ),
          child: SizedBox(
            width: width,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewport.maxHeight / scale,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    header,
                    for (final section in sections)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                        child: section,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        return SingleChildScrollView(
          key: const PageStorageKey('home-overview-scroll'),
          child: Align(
            alignment: Alignment.topCenter,
            child: compactOverview
                ? SizedBox(
                    width: viewport.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      child: content,
                    ),
                  )
                : content,
          ),
        );
      },
    );
  }
}
