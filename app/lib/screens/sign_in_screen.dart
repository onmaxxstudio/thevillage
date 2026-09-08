import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/village_app_shell.dart';
import '../services/auth_service.dart';
import 'create_account_screen.dart';
import 'village_promise_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF496B4F);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFD9D1C3);

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;
  bool loading = false;

  final auth = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await authenticate(
      'Email sign-in',
      () => auth.signInWithEmail(
        emailController.text,
        passwordController.text,
      ),
    );
  }

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

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email address first.')),
      );
      return;
    }
    try {
      await auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.messageFor(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: Column(
                children: [
                  _BrandHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1E8),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: sage,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel('Email'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: emailController,
                            decoration: fieldDecoration(
                              'Enter your email',
                              Icons.mail_outline_rounded,
                            ),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Enter your email'
                                : null,
                          ),
                          const SizedBox(height: 17),
                          const _FieldLabel('Password'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            decoration: fieldDecoration(
                              'Enter your password',
                              Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => hidePassword = !hidePassword),
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your password'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: loading ? null : resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: loading ? null : submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: sage,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: line)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or continue with'),
                              ),
                              Expanded(child: Divider(color: line)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  icon: Icons.apple,
                                  label: 'Apple',
                                  onPressed: loading
                                      ? null
                                      : () => _showAppleUnavailable(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SocialButton(
                                  icon: Icons.g_mobiledata_rounded,
                                  label: 'Google',
                                  onPressed: loading
                                      ? null
                                      : () => authenticate('Google sign-in', auth.signInWithGoogle),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EBDD),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sage),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.phone_iphone_rounded,
                            color: sage,
                            size: 30,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Preview the Full App',
                            style: GoogleFonts.inter(
                              color: sage,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Open the complete working app without signing in while account setup is being finished.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const VillageAppShell(),
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: sage,
                                padding: const EdgeInsets.all(14),
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Preview the Full App'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Trouble signing in?',
                    style: GoogleFonts.inter(
                      color: sage,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text('We can help you get back on track.'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : resetPassword,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: sage),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: const Text('Recover My Account'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('New to Ask the Village? '),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const CreateAccountScreen(),
                          ),
                        ),
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration fieldDecoration(String hint, IconData icon) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: line),
    );
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: sage),
      filled: true,
      fillColor: const Color(0xFFFFFCF7),
      border: border,
      enabledBorder: border,
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        Column(
          children: [
            Image.asset(
              'assets/images/welcome_branch.png',
              width: 68,
              height: 28,
            ),
            Text(
              'Ask the Village',
              style: GoogleFonts.playfairDisplay(
                fontSize: 46,
                fontWeight: FontWeight.w600,
                color: _SignInScreenState.sage,
              ),
            ),
            Text(
              "Welcome back. We’re glad you’re here.",
              style: GoogleFonts.inter(fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _SignInScreenState.ink,
          backgroundColor: const Color(0xFFFFFCF7),
          side: const BorderSide(color: _SignInScreenState.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        icon: Icon(icon, size: 25),
        label: Text(label),
      ),
    );
  }
}
