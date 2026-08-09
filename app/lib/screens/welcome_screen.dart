import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'create_account_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _cream = Color(0xFFFFFAF1);
  static const _green = Color(0xFF496B4F);
  static const _sage = Color(0xFF66845F);
  static const _gold = Color(0xFFC8A35E);
  static const _ink = Color(0xFF171A17);
  static const _muted = Color(0xFF5D5E5D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const _HeroImage(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 15, 22, 24),
                      child: Column(
                        children: [
                          Text(
                            'The Village',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: _green,
                              fontSize: 51,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _BotanicalDivider(),
                          const SizedBox(height: 14),
                          Text(
                            'Real People. Real Support. Real Connection.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: _ink,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _WelcomeHome(),
                          const SizedBox(height: 6),
                          Text(
                            'A place to ask. A place to belong.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: _muted,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _FeaturePanel(),
                          const SizedBox(height: 23),
                          _PrimaryButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const CreateAccountScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const _SignInButton(),
                          const SizedBox(height: 22),
                          const _PrivacyMessage(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ClipPath(
          clipper: const _HeroArchClipper(),
          child: SizedBox(
            width: width,
            height: width * (590 / 853),
            child: Image.asset(
              'assets/images/welcome_hero.png',
              alignment: Alignment.topCenter,
              fit: BoxFit.fitWidth,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      },
    );
  }
}

class _HeroArchClipper extends CustomClipper<Path> {
  const _HeroArchClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * .89)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.08,
        size.width,
        size.height * .89,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _HeroArchClipper oldClipper) => false;
}

class _BotanicalDivider extends StatelessWidget {
  const _BotanicalDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 76, child: Divider(color: WelcomeScreen._gold)),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          height: 23,
          child: Center(
            child: OverflowBox(
              maxWidth: 65,
              maxHeight: 30,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 65, maxHeight: 30),
                child: Image.asset(
                  'assets/images/welcome_branch.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const SizedBox(width: 76, child: Divider(color: WelcomeScreen._gold)),
      ],
    );
  }
}

class _WelcomeHome extends StatelessWidget {
  const _WelcomeHome();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Home.',
          style: GoogleFonts.allura(
            color: WelcomeScreen._green,
            fontSize: 49,
            height: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 1, left: 5),
          child: Icon(
            Icons.favorite_border_rounded,
            color: WelcomeScreen._gold,
            size: 25,
          ),
        ),
      ],
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel();

  static const _features = <(IconData, String)>[
    (Icons.groups_2_outlined, 'Real\nCommunity'),
    (Icons.shield_outlined, 'Private &\nSecure'),
    (Icons.volunteer_activism_outlined, 'Judgment-Free\nSupport'),
    (Icons.eco_outlined, 'Growth &\nWellness'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < _features.length; index++) ...[
            Expanded(
              child: _Feature(
                icon: _features[index].$1,
                label: _features[index].$2,
                showLock: index == 1,
              ),
            ),
            if (index != _features.length - 1)
              const SizedBox(
                height: 58,
                child: VerticalDivider(color: Color(0xFFDED8CC), width: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.label,
    this.showLock = false,
  });

  final IconData icon;
  final String label;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 38, color: WelcomeScreen._sage),
            if (showLock)
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: WelcomeScreen._green,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: WelcomeScreen._ink,
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: WelcomeScreen._sage,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Join The Village',
          style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 57,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: WelcomeScreen._green,
          side: const BorderSide(color: WelcomeScreen._green, width: 1.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'I already have an account',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _PrivacyMessage extends StatelessWidget {
  const _PrivacyMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 19,
          color: WelcomeScreen._sage,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            "Your privacy matters. You're in a safe place.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: WelcomeScreen._muted,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
