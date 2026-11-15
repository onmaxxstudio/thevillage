import 'package:flutter/material.dart';

/// The composer uses the real viewport rather than a scaled dashboard canvas.
class AskPageLayout extends StatelessWidget {
  const AskPageLayout({
    super.key,
    required this.header,
    required this.sections,
  });

  final Widget header;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      final mobile = viewport.maxWidth < 600;
      return SingleChildScrollView(
        key: const PageStorageKey('ask-page-scroll'),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                for (final section in sections)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      mobile ? 11 : 24,
                      4,
                      mobile ? 11 : 24,
                      24,
                    ),
                    child: section,
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
