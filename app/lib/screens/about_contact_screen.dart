import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const _green = Color(0xFF355C3B);
const _ink = Color(0xFF152F1C);
const _cream = Color(0xFFFFFAF1);
const _pale = Color(0xFFEDF0DF);

class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        centerTitle: true, backgroundColor: _cream, foregroundColor: _ink,
        title: const Text('About & Contact'),
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: CustomPaint(
          painter: _VillageBackdrop(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _hero(context),
                    const SizedBox(height: 32),
                    _mission(context),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(28)),
                      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.favorite_border_rounded, color: _green, size: 38),
                        SizedBox(width: 18),
                        Expanded(child: Text(
                          'We make room for honest conversations, including the topics too often left unspoken. Come with your questions, your struggles, your small victories, and your unfinished chapters.',
                          style: TextStyle(fontSize: 16, height: 1.5, color: _ink),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    CustomPaint(
                      painter: _BrushBanner(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        child: Column(children: [
                          Text('You don’t have to pretend you’re okay just because you’re capable.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 17, height: 1.5)),
                          Text('You deserve support, too.', textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 19, height: 1.5, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Everyone deserves a village. Welcome to yours.',
                      textAlign: TextAlign.center, style: TextStyle(color: _green, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 24),
                    const _FounderSection(),
                    const SizedBox(height: 24),
                    _contact(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final compact = constraints.maxWidth < 600;
    final heading = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Everyone deserves a village.',
        style: TextStyle(color: _ink, fontSize: compact ? 30 : 42,
          fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.8)),
      const SizedBox(height: 10),
      Container(height: 5, width: compact ? 150 : 320,
        decoration: BoxDecoration(color: const Color(0xFFE4C985), borderRadius: BorderRadius.circular(20))),
    ]);
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(Icons.diversity_1_outlined, color: const Color(0xFF4D692F), size: compact ? 60 : 88),
        const SizedBox(width: 18), Expanded(child: heading),
      ]),
      const SizedBox(height: 18),
      Text('REAL PEOPLE.  REAL SUPPORT.  REAL ANSWERS.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _ink, fontSize: compact ? 12 : 17, letterSpacing: 1.7, height: 1.6)),
    ]);
  });

  Widget _mission(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF7),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(40)),
        child: const Text('About Ask the Village',
          style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 22),
      LayoutBuilder(builder: (context, constraints) {
        const story = Text(
          'Ask the Village is a community where people share, learn, and grow together—because no one should have to navigate life’s different seasons alone.\n\n'
          'Here, your neighbors’ experiences become shared wisdom. Learn from their mistakes, find encouragement in their wins, and share the lessons you’ve gathered along the way. Your story might be the support someone else needs.',
          style: TextStyle(color: _ink, fontSize: 16, height: 1.5),
        );
        final badges = Column(children: [
          _badge(Icons.forum_outlined, 'Honest Conversations'),
          _badge(Icons.spa_outlined, 'Real Support'),
          _badge(Icons.menu_book_rounded, 'Shared Learning'),
          _badge(Icons.favorite_border_rounded, 'A Safe, Welcoming Space'),
        ]);
        if (constraints.maxWidth < 650) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            story, const SizedBox(height: 22), badges,
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(flex: 3, child: story),
          Container(width: 1, height: 265, margin: const EdgeInsets.symmetric(horizontal: 28), color: const Color(0xFFCAD3B3)),
          Expanded(flex: 2, child: badges),
        ]);
      }),
    ]),
  );

  Widget _badge(IconData icon, String title) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(40)),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF4D692F), size: 32),
      const SizedBox(width: 16),
      Expanded(child: Text(title, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _contact(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF355C3B), Color(0xFF435E38)]),
      borderRadius: BorderRadius.circular(28),
    ),
    child: LayoutBuilder(builder: (context, constraints) {
      final message = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.mail_outline_rounded, color: Color(0xFFE4C985), size: 40),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Contact us', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Have a question, need technical support, want to share feedback, or interested in partnering with Ask the Village?',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
        ])),
      ]);
      final actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDCE5C8), foregroundColor: _ink,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
          onPressed: () => _emailSupport(context),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text('support@askthevillage.app', style: TextStyle(fontWeight: FontWeight.w700))),
            SizedBox(width: 8), Icon(Icons.send_outlined, size: 20),
          ]),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: 'support@askthevillage.app'));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email address copied.')));
          },
          icon: const Icon(Icons.copy_outlined, size: 16),
          label: const Text('Copy email address'),
        ),
        Semantics(label: 'Email support', child: TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () => _emailSupport(context), child: const Text('Email support'))),
      ]);
      if (constraints.maxWidth < 750) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          message, const SizedBox(height: 20), actions,
        ]);
      }
      return Row(children: [
        Expanded(child: message), const SizedBox(width: 28),
        SizedBox(width: 310, child: actions),
      ]);
    }),
  );

  Future<void> _emailSupport(BuildContext context) async {
    try {
      if (await launchUrl(Uri(scheme: 'mailto', path: 'support@askthevillage.app'))) return;
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Unable to open your email app. Copy the email address to contact us.')));
  }
}

class _VillageBackdrop extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()..moveTo(0, 0)..lineTo(0, 180)
      ..quadraticBezierTo(size.width * .45, 300, size.width, 110)
      ..lineTo(size.width, 0)..close();
    canvas.drawPath(wave, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFD9E1BF), Color(0xFFFFFAF1), Color(0xFFDEE5CC)]
    ).createShader(Rect.fromLTWH(0,0,size.width,300)));
    canvas.save();
    canvas.translate(size.width - 8, 12);
    canvas.rotate(-.3);
    final branch = Paint()..color = const Color(0xFF6E854B).withValues(alpha: .35)
      ..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0,-10), const Offset(-50,155), branch);
    for (var i=0; i<5; i++) {
      canvas.save();
      canvas.translate(-i*9.0,i*29.0);
      canvas.rotate(i.isEven ? -.8 : .9);
      final leaf = Path()..moveTo(0,0)..quadraticBezierTo(-38,-27,-67,0)
        ..quadraticBezierTo(-32,20,0,0)..close();
      canvas.drawPath(leaf, Paint()..color = const Color(0xFF6E854B).withValues(alpha:.3));
      canvas.restore();
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _VillageBackdrop oldDelegate) => false;
}

class _BrushBanner extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _green;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8,4,size.width-16,size.height-8), const Radius.circular(24)), paint);

  }
  @override
  bool shouldRepaint(covariant _BrushBanner oldDelegate) => false;
}

class _FounderSection extends StatelessWidget {
  const _FounderSection();

  static const _sage = Color(0xFF355C3B);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('founder-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meet the Founder',
            style: GoogleFonts.caveat(fontSize: 38, color: _sage, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 550;
              final portrait = SizedBox(
                key: const ValueKey('founder-portrait'),
                width: sideBySide ? 210 : 240,
                height: (sideBySide ? 210 : 240) * 1250 / 1086,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: const Color(0xFFDDE5C7), borderRadius: BorderRadius.circular(120)),
                  child: kIsWeb
                    ? Image.network(
                        Uri.base
                            .resolve('assets/assets/images/ariel-founder.webp')
                            .toString(),
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        fit: BoxFit.contain,
                        semanticLabel:
                            'Ariel Mitchell, founder of Ask the Village',
                      )
                    : Image.asset(
                        'assets/images/ariel-founder.webp',
                        fit: BoxFit.contain,
                        semanticLabel:
                            'Ariel Mitchell, founder of Ask the Village',
                      ),
                ),
              );
              final message = Column(
                key: const ValueKey('founder-message'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ariel Mitchell',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _sage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Founder of Ask the Village',
                    style: TextStyle(fontSize: 14, height: 1.5, color: _sage),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '“I created Ask the Village because I believe no one should '
                    'have to navigate every season of life alone. Sometimes we '
                    'don’t need someone to fix everything. We just need somewhere '
                    'to be heard, understood, and reminded that we’re not alone.”',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.65,
                      color: Color(0xFF172019),
                    ),
                  ),
                ],
              );
              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    portrait,
                    const SizedBox(width: 28),
                    Expanded(child: message),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: portrait),
                  const SizedBox(height: 24),
                  message,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
