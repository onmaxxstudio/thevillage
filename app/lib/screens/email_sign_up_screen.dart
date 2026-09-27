import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'village_promise_screen.dart';

class EmailSignUpScreen extends StatefulWidget {
  const EmailSignUpScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  static const sage = Color(0xFF496B4F);
  static const cream = Color(0xFFFFFAF1);
  static const line = Color(0xFFD9D1C3);

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = false;
  bool hidePassword = true;

  AuthService get auth => widget.authService ?? AuthService();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading || !(formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    try {
      await auth.createAccount(
        name: usernameController.text,
        email: emailController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const VillagePromiseScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.messageFor(error))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration(String label, IconData icon) {
      final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      );
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: const Color(0xFF666762), fontSize: 17),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
        prefixIcon: Icon(icon, color: sage),
        filled: true,
        fillColor: const Color(0xFFFFFCF7),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: sage, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24),
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24),
          ),
        ),
        title: Text('Create Account', style: GoogleFonts.inter(fontSize: 22)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF4EEDF),
        foregroundColor: const Color(0xFF354337),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/email_signup_hero.jpg',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      filterQuality: FilterQuality.high,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Join Ask the Village',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                color: sage,
                                fontSize: 38,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Real people. Real support. A village that shows up.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF343630),
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 26),
                          TextFormField(
                            controller: usernameController,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            autofillHints: const [AutofillHints.newUsername],
                            textInputAction: TextInputAction.next,
                            decoration: decoration('Username', Icons.alternate_email),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Enter a username'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: emailController,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.email],
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: decoration('Email', Icons.mail_outline),
                            validator: (value) => value == null ||
                                    !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                        .hasMatch(value.trim())
                                ? 'Enter a valid email address'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [AutofillHints.newPassword],
                            obscureText: hidePassword,
                            textInputAction: TextInputAction.next,
                            decoration: decoration('Password', Icons.lock_outline)
                                .copyWith(
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => hidePassword = !hidePassword),
                                tooltip: hidePassword ? 'Show password' : 'Hide password',
                                icon: Icon(hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) < 6
                                ? 'Use at least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: confirmController,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            obscureText: hidePassword,
                            onFieldSubmitted: (_) => submit(),
                            decoration:
                                decoration('Confirm password', Icons.lock_outline),
                            validator: (value) => value != passwordController.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: loading ? null : submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: sage,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                textStyle: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
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
                                  : const Text('Create My Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
