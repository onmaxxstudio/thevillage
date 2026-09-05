import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sign_in_screen.dart';
import 'village_promise_screen.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  static const _referenceAsset = 'design/02-create-account-and-sign-in.png';
  static const _heroAsset = 'assets/images/create_account_hero.png';
  static const _sage = Color(0xFF496B4F);
  static const _ink = Color(0xFF172019);
  static const _cream = Color(0xFFFFFAF1);
  static const _line = Color(0xFFD9D1C3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                        _Header(onBack: () => Navigator.of(context).pop()),
                        const _ApprovedCommunityImage(),
                        Transform.translate(
                          offset: const Offset(0, -1),
                          child: const _AccountCard(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
          child: Column(
            children: [
              const _BotanicalMark(),
              Text(
                'The Village',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 46,
                  fontWeight: FontWeight.w600,
                  height: 1.06,
                  color: CreateAccountScreen._sage,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Real People. Real Support. Real Connection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CreateAccountScreen._ink,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: 17,
          child: IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24),
            color: CreateAccountScreen._ink,
          ),
        ),
      ],
    );
  }
}

class _BotanicalMark extends StatelessWidget {
  const _BotanicalMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 28,
      child: Image.asset(
        'assets/images/welcome_branch.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ApprovedCommunityImage extends StatelessWidget {
  const _ApprovedCommunityImage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: AspectRatio(
        aspectRatio: 549 / 350,
        child: Image.asset(
          CreateAccountScreen._heroAsset,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _ReferenceCrop extends StatelessWidget {
  const _ReferenceCrop({
    required this.sourceLeft,
    required this.sourceTop,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  final double sourceLeft;
  final double sourceTop;
  final double sourceWidth;
  final double sourceHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / sourceWidth <
                constraints.maxHeight / sourceHeight
            ? constraints.maxWidth / sourceWidth
            : constraints.maxHeight / sourceHeight;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -sourceLeft * scale,
                top: -sourceTop * scale,
                width: 1210 * scale,
                height: 1300 * scale,
                child: Image.asset(
                  CreateAccountScreen._referenceAsset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 21, 28, 25),
      decoration: const BoxDecoration(
        color: CreateAccountScreen._cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Create Your Account',
            style: GoogleFonts.inter(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: CreateAccountScreen._sage,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Join a safe, judgment-free community\nwhere you can be you.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              height: 1.42,
              color: CreateAccountScreen._ink,
            ),
          ),
          const SizedBox(height: 19),
          _AuthButton(
            icon: const Icon(Icons.apple, size: 26),
            label: 'Continue with Apple',
            onPressed: () => _continueToPromise(context),
          ),
          const SizedBox(height: 11),
          _AuthButton(
            icon: const _GoogleMark(),
            label: 'Continue with Google',
            onPressed: () => _continueToPromise(context),
          ),
          const SizedBox(height: 11),
          _AuthButton(
            icon: const Icon(Icons.mail_outline_rounded,
                size: 27, color: CreateAccountScreen._sage),
            label: 'Continue with Email',
            onPressed: () => _continueToPromise(context),
          ),
          const SizedBox(height: 17),
          const _Divider(),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Already have an account? ',
                  style: GoogleFonts.inter(fontSize: 14)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignInScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(42, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: CreateAccountScreen._sage,
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _PrivacyCard(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _continueToPromise(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VillagePromiseScreen()),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: CreateAccountScreen._ink,
          backgroundColor: const Color(0xFFFFFCF7),
          side: const BorderSide(color: CreateAccountScreen._line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(child: icon),
            ),
            Center(
              child: Text(label, style: GoogleFonts.inter(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC9CDB9)),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: CreateAccountScreen._sage,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your privacy matters.',
                  style: GoogleFonts.inter(
                    color: CreateAccountScreen._sage,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'We never sell your data. Your journey, your story, stays with you.',
                  style: GoogleFonts.inter(
                    color: CreateAccountScreen._ink,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 27,
      height: 27,
      child: _ReferenceCrop(
        sourceLeft: 99,
        sourceTop: 832,
        sourceWidth: 42,
        sourceHeight: 42,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: CreateAccountScreen._line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text('or', style: GoogleFonts.inter(fontSize: 13)),
        ),
        const Expanded(child: Divider(color: CreateAccountScreen._line)),
      ],
    );
  }
}

// Privacy card intentionally removed to match approved Create Account design.
