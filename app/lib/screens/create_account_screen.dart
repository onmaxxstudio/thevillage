import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/village_app_shell.dart';
import '../services/auth_service.dart';
import 'email_sign_up_screen.dart';
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

  Future<void> _showAppleUnavailable() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apple sign-in is not available yet'),
        content: const Text(
          'Apple must be enabled and connected in Firebase before this button '
          'can sign you in. Please use Google or email for now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
              Text(
                'Ask the Village',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 51,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: CreateAccountScreen._sage,
                ),
              ),
              const SizedBox(height: 12),
              const _WelcomeStyleDivider(),
              const SizedBox(height: 12),
              Text(
                'Real People. Real Support. Real Answers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
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

class _WelcomeStyleDivider extends StatelessWidget {
  const _WelcomeStyleDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 76,
          child: Divider(color: Color(0xFFC8A35E)),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          height: 25,
          child: Image.asset(
            'assets/images/welcome_branch.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        const SizedBox(
          width: 76,
          child: Divider(color: Color(0xFFC8A35E)),
        ),
      ],
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

class _AccountCard extends StatefulWidget {
  const _AccountCard();

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  final auth = AuthService();
  bool loading = false;

  Future<void> authenticate(
    String method,
    Future<Object?> Function() action,
  ) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      await action();
      final acceptedPromise = await auth.hasAcceptedVillagePromise();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => acceptedPromise
              ? const VillageAppShell()
              : const VillagePromiseScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = AuthService.messageFor(error);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('$method error'),
          content: SelectableText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

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
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w600,
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
            onPressed: loading
                ? null
                : () => _showAppleUnavailable(),
          ),
          const SizedBox(height: 11),
          _AuthButton(
            icon: const _GoogleMark(),
            label: 'Continue with Google',
            onPressed: loading
                ? null
                : () => authenticate('Google sign-in', auth.signInWithGoogle),
          ),
          const SizedBox(height: 11),
          _AuthButton(
            icon: const Icon(Icons.mail_outline_rounded,
                size: 27, color: CreateAccountScreen._sage),
            label: 'Continue with Email',
            onPressed: loading
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EmailSignUpScreen(),
                      ),
                    ),
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
          const SizedBox(height: 10),
        ],
      ),
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
  final VoidCallback? onPressed;

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
