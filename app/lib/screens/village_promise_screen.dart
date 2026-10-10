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
  bool get agreed => selectedPromises.length == promises.length;
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
                    'assets/images/create_account_photo.jpg',
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F1E8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFC9CDB9)),
                            ),
                            child: CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: censusConsent,
                              activeColor: sage,
                              onChanged: saving
                                  ? null
                                  : (value) => setState(() => censusConsent = value ?? false),
                              title: Text(
                                'Help Us Learn & Grow (Optional)',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                ),
                              ),
                              subtitle: Text(
                                'Allow my Village Question answers to be included in grouped, anonymous reports shared or sold to research or marketing partners.',
                                style: GoogleFonts.inter(fontSize: 11.5, color: ink, height: 1.32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your 3 required Village promises',
                            style: GoogleFonts.inter(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (var index = 0; index < promises.length; index++) ...[
                            _PromiseRow(
                              icon: promises[index].$1,
                              title: promises[index].$2,
                              text: promises[index].$3,
                              checked: selectedPromises.contains(index),
                              enabled: !saving,
                              onChanged: (checked) => setState(() {
                                if (checked) {
                                  selectedPromises.add(index);
                                } else {
                                  selectedPromises.remove(index);
                                }
                              }),
                            ),
                            const SizedBox(height: 10),
                          ],
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
                                'Continue to the Village',
                                style: TextStyle(fontSize: 19),
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          SizedBox(
                            width: double.infinity,
                            height: 51,
                            child: OutlinedButton(
                              onPressed: () => showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Community Standards'), content: const Text('Be respectful. Protect privacy. Keep it safe. Report harmful behavior.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))])),
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
  const _PromiseRow({
    required this.icon,
    required this.title,
    required this.text,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String text;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!checked) : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1E8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: checked ? _VillagePromiseScreenState.sage : const Color(0xFFC9CDB9),
            width: checked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC9CDB9)),
              ),
              child: Icon(icon, color: _VillagePromiseScreenState.sage),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.playfairDisplay(color: _VillagePromiseScreenState.ink, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(text, style: GoogleFonts.inter(color: _VillagePromiseScreenState.ink, fontSize: 12.5, height: 1.3)),
                ],
              ),
            ),
            Checkbox(
              value: checked,
              activeColor: _VillagePromiseScreenState.sage,
              onChanged: enabled ? (value) => onChanged(value ?? false) : null,
            ),
          ],
        ),
      ),
    );
  }
}
