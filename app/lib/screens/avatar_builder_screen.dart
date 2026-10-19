import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/profile_service.dart';
import '../widgets/village_avatar.dart';

class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key, required this.profile});

  final VillageProfile profile;

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  static const skinColors = <Color>[
    Color(0xFF6E3E2E), Color(0xFF9C6045), Color(0xFFC98761),
    Color(0xFFE0AD86), Color(0xFFEDC29B), Color(0xFF81513D),
  ];
  static const hairColors = <Color>[
    Color(0xFF171311), Color(0xFF2D211C), Color(0xFF542F23),
    Color(0xFF8A5837), Color(0xFFB78A58), Color(0xFF4A4A47),
  ];
  static const hairStyles = ['Coils', 'Locs', 'Braids', 'Waves', 'Short', 'Bun'];
  static const faceShapes = ['Soft', 'Long', 'Round'];
  static const eyeStyles = ['Almond', 'Round', 'Gentle'];
  static const expressions = ['Smile', 'Big smile', 'Calm'];

  late int skin = widget.profile.avatarSkin;
  late int hair = widget.profile.avatarHair;
  late int hairColor = widget.profile.avatarHairColor;
  late int face = widget.profile.avatarFace.clamp(0, 2).toInt();
  late int eyes = widget.profile.avatarEyes.clamp(0, 2).toInt();
  late int smile = widget.profile.avatarSmile.clamp(0, 2).toInt();
  bool saving = false;

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await ProfileService().updateAvatar(
        mode: 'avatar',
        key: widget.profile.avatarKey,
        skin: skin,
        hair: hair,
        hairColor: hairColor,
        face: face,
        eyes: eyes,
        smile: smile,
      );
      VillageAvatar.invalidate(widget.profile.uid);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your avatar: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: sage,
        elevation: 0,
        title: Text('Build your avatar', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFB78943)),
                      child: VillageAvatar(
                        uid: widget.profile.uid,
                        radius: 67,
                        avatarMode: 'avatar',
                        avatarKey: widget.profile.avatarKey,
                        avatarSkin: skin,
                        avatarHair: hair,
                        avatarHairColor: hairColor,
                        avatarFace: face,
                        avatarEyes: eyes,
                        avatarSmile: smile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(child: Text('Make it feel like you.', style: TextStyle(color: Color(0xFF667769)))),
                  const SizedBox(height: 22),
                  _sectionTitle('Skin colour'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 12, runSpacing: 10, children: [
                    for (var index = 0; index < skinColors.length; index++)
                      _colorChoice(skinColors[index], selected: skin == index, onTap: () => setState(() => skin = index), label: 'Skin tone ${index + 1}'),
                  ]),
                  const SizedBox(height: 22),
                  _sectionTitle('Hair style'),
                  const SizedBox(height: 9),
                  _choices(hairStyles, hair, (value) => setState(() => hair = value)),
                  const SizedBox(height: 20),
                  _sectionTitle('Hair colour'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 12, runSpacing: 10, children: [
                    for (var index = 0; index < hairColors.length; index++)
                      _colorChoice(hairColors[index], selected: hairColor == index, onTap: () => setState(() => hairColor = index), label: 'Hair colour ${index + 1}'),
                  ]),
                  const SizedBox(height: 22),
                  _sectionTitle('Face shape'),
                  const SizedBox(height: 9),
                  _choices(faceShapes, face, (value) => setState(() => face = value)),
                  const SizedBox(height: 20),
                  _sectionTitle('Eyes'),
                  const SizedBox(height: 9),
                  _choices(eyeStyles, eyes, (value) => setState(() => eyes = value)),
                  const SizedBox(height: 20),
                  _sectionTitle('Expression'),
                  const SizedBox(height: 9),
                  _choices(expressions, smile, (value) => setState(() => smile = value)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: Text(saving ? 'Saving…' : 'Save my avatar', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) => Text(label, style: GoogleFonts.playfairDisplay(color: ink, fontSize: 20, fontWeight: FontWeight.w700));

  Widget _choices(List<String> labels, int selected, ValueChanged<int> onSelect) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (var index = 0; index < labels.length; index++)
        ChoiceChip(
          label: Text(labels[index]),
          selected: selected == index,
          onSelected: (_) => onSelect(index),
          selectedColor: const Color(0xFFE8EBDD),
          backgroundColor: Colors.white,
          side: BorderSide(color: selected == index ? sage : line),
          labelStyle: TextStyle(color: selected == index ? sage : ink, fontWeight: FontWeight.w600),
        ),
    ]);
  }

  Widget _colorChoice(Color color, {required bool selected, required VoidCallback onTap, required String label}) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: selected ? sage : Colors.white, width: selected ? 3 : 2), boxShadow: selected ? const [BoxShadow(color: Color(0x22000000), blurRadius: 4)] : null),
          child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 17) : null,
        ),
      ),
    );
  }
}
