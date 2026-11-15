import 'package:flutter/material.dart';

import 'browser_layout_width.dart';

/// Keeps the phone overview in the horizontal arrangement used on tablets.
/// Only this dashboard is scaled; routes opened from it use normal device size.
class HomeOverviewLayout extends StatelessWidget {
  const HomeOverviewLayout({
    super.key,
    required this.header,
    required this.sections,
    this.distributeSections = true,
  });

  final Widget header;
  final List<Widget> sections;
  final bool distributeSections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) {
        final media = MediaQuery.of(context);
        final browserWidth = phoneBrowserWidth();
        final compactOverview =
            (browserWidth ?? viewport.maxWidth) < 600 &&
            media.textScaler.scale(1) <= 1.3;
        // Reduce the logical canvas when browser zoom narrows the viewport.
        // Text and cards then reflow vertically instead of adding horizontal
        // scrolling. At 100% the original 768px canvas is unchanged.
        final zoom = browserWidth == null
            ? 1.0
            : browserWidth / viewport.maxWidth;
        final width = compactOverview
            ? (768.0 / zoom).clamp(viewport.maxWidth, 1100.0)
            : viewport.maxWidth.clamp(0.0, 1100.0);
        final scale = compactOverview ? viewport.maxWidth / width : 1.0;
        final content = MediaQuery(
          data: media.copyWith(
            size: Size(width, media.size.height / scale),
            textScaler: TextScaler.linear(media.textScaler.scale(1) * 1.22),
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
                  mainAxisAlignment: distributeSections
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.start,
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
        final fitted = SizedBox(
          width: viewport.maxWidth,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: content,
          ),
        );
        return SingleChildScrollView(
          key: const PageStorageKey('home-overview-scroll'),
          child: Align(
            alignment: Alignment.topCenter,
            child: compactOverview ? fitted : content,
          ),
        );
      },
    );
  }
}
