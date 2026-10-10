import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/village_app_shell.dart';
import '../services/auth_service.dart';

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
  final selectedPromises = <int>{};
  bool get agreed => selectedPromises.length == 3;
  bool censusConsent = false;
  bool saving = false;

  Future<void> acceptPromise() async {
    if (!agreed || saving) return;
    setState(() => saving = true);
    try {
      await auth.saveCensusConsent(censusConsent);
      await auth.acceptVillagePromise();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const VillageAppShell()),
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

  static const promises = <(IconData, String, String)>[
    (Icons.shield_outlined, 'Be Respectful', 'Keep conversations kind, supportive, and respectful.'),
    (Icons.groups_2_outlined, 'Keep It Real', 'Share honestly and listen with an open mind.'),
    (Icons.lock_outline_rounded, 'Respect Privacy', 'Don’t share personal information about others.'),
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
                          Text('The Village Promise',
                            style: GoogleFonts.playfairDisplay(color: sage, fontSize: 32, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Please accept all three Village Promises to continue.',
                            style: GoogleFonts.inter(color: ink, fontSize: 14)),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFFFFFCF7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE3D8C9))),
                            child: Column(children: [
                              for (var i = 0; i < promises.length; i++) ...[
                                InkWell(
                                  onTap: saving ? null : () => setState(() {
                                    if (!selectedPromises.add(i)) selectedPromises.remove(i);
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                    child: Row(children: [
                                      CircleAvatar(backgroundColor: i == 0 ? const Color(0xFFE8EBDD) : i == 1 ? const Color(0xFFF3E2DD) : const Color(0xFFF5E4CE),
                                        child: Icon(promises[i].$1, color: sage)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(promises[i].$2, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: ink)),
                                        Text(promises[i].$3, style: GoogleFonts.inter(fontSize: 12.5, color: ink)),
                                      ])),
                                      Checkbox(value: selectedPromises.contains(i), activeColor: sage,
                                        onChanged: saving ? null : (value) => setState(() {
                                          if (value == true) { selectedPromises.add(i); } else { selectedPromises.remove(i); }
                                        })),
                                    ]),
                                  ),
                                ),
                                if (i != promises.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                              ],
                            ]),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFF3E2DD), borderRadius: BorderRadius.circular(20)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.bar_chart_rounded, color: sage),
                                const SizedBox(width: 10),
                                Expanded(child: Text('Help Us Learn & Grow', style: GoogleFonts.playfairDisplay(fontSize: 20, color: ink, fontWeight: FontWeight.w600))),
                                Text('Optional', style: GoogleFonts.inter(fontSize: 12, color: sage)),
                              ]),
                              const SizedBox(height: 10),
                              Text('With your permission, your Village Question answers may be included in grouped reports sold or shared with research or marketing partners. They receive totals only, not your account or individual vote.',
                                style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: ink)),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                value: censusConsent,
                                activeColor: sage,
                                onChanged: saving ? null : (value) => setState(() => censusConsent = value ?? false),
                                title: Text('I agree to include my answers in these reports.', style: GoogleFonts.inter(fontSize: 13, color: ink)),
                                subtitle: Text('You can join and vote without agreeing.', style: GoogleFonts.inter(fontSize: 11, color: ink)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity, height: 55,
                            child: FilledButton(
                              onPressed: agreed && !saving ? acceptPromise : null,
                              style: FilledButton.styleFrom(backgroundColor: sage,
                                disabledBackgroundColor: sage.withValues(alpha: 0.38),
                                shape: const StadiumBorder()),
                              child: Text(saving ? 'Saving…' : 'Continue to the Village',
                                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          if (!agreed) Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Text('All three promises are required to continue.',
                              style: GoogleFonts.inter(fontSize: 12, color: sage)),
                          ),
                          const SizedBox(height: 8),
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

