import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

class VillagePromiseScreen extends StatefulWidget {
  const VillagePromiseScreen({super.key});

  @override
  State<VillagePromiseScreen> createState() => _VillagePromiseScreenState();
}

class _VillagePromiseScreenState extends State<VillagePromiseScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF496B4F);
  static const gold = Color(0xFFC8A35E);
  static const ink = Color(0xFF172019);

  final auth = AuthService();
  bool agreed = false;
  bool saving = false;

  Future<void> acceptPromise() async {
    if (!agreed || saving) return;
    setState(() => saving = true);
    try {
      await auth.acceptVillagePromise();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.messageFor(error))),
      );
      setState(() => saving = false);
    }
  }

  static const promises = <(IconData, String)>[
    (Icons.favorite_border_rounded, 'I will treat people with kindness.'),
    (Icons.lock_outline_rounded, 'I will respect privacy.'),
    (Icons.volunteer_activism_outlined, 'I will offer support without judgment.'),
    (Icons.groups_2_outlined, 'I will help make our village feel safe and welcoming.'),
  ];

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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/welcome_branch.png',
                          width: 70,
                          height: 28,
                        ),
                        Text(
                          'Ask the Village',
                          style: GoogleFonts.playfairDisplay(
                            color: sage,
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/create_account_hero.png',
                    width: double.infinity,
                    height: 210,
                    fit: BoxFit.cover,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(25, 22, 25, 25),
                      decoration: const BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(34),
                          topRight: Radius.circular(34),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            color: gold,
                            size: 33,
                          ),
                          Text(
                            'Before you enter,',
                            style: GoogleFonts.playfairDisplay(
                              color: sage,
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'one simple promise.',
                            style: GoogleFonts.allura(color: sage, fontSize: 40),
                          ),
                          const SizedBox(height: 14),
                          for (final promise in promises) ...[
                            _PromiseRow(icon: promise.$1, text: promise.$2),
                            const SizedBox(height: 10),
                          ],
                          InkWell(
                            onTap: () => setState(() => agreed = !agreed),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: agreed,
                                    activeColor: sage,
                                    onChanged: (value) =>
                                        setState(() => agreed = value ?? false),
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'I agree to the Village Promise.',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: FilledButton.icon(
                              onPressed:
                                  agreed && !saving ? acceptPromise : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: sage,
                                disabledBackgroundColor: sage.withValues(alpha: 0.38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.favorite_border_rounded),
                              label: const Text(
                                'I Promise',
                                style: TextStyle(fontSize: 19),
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          SizedBox(
                            width: double.infinity,
                            height: 51,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: sage),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Read Community Standards'),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromiseRow extends StatelessWidget {
  const _PromiseRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC9CDB9)),
            ),
            child: Icon(icon, color: _VillagePromiseScreenState.sage),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: _VillagePromiseScreenState.ink,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
