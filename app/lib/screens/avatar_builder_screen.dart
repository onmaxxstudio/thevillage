import 'dart:math';

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
  static const muted = Color(0xFF718071);
  static const line = Color(0xFFE8E1D6);

  static const skinColors = <Color>[
    Color(0xFF3B2119), Color(0xFF563326), Color(0xFF704630),
    Color(0xFF81513D), Color(0xFF8B553A), Color(0xFF9C6045),
    Color(0xFFA66A4E), Color(0xFFB97855), Color(0xFFC98761),
    Color(0xFFD69A70), Color(0xFFE0AD86), Color(0xFFEDC29B),
  ];
  static const hairColors = <Color>[
    Color(0xFF171311), Color(0xFF2D211C), Color(0xFF542F23),
    Color(0xFF8A5837), Color(0xFFC17C36), Color(0xFFE1BE78),
    Color(0xFF4A4A47), Color(0xFFE1D9CC), Color(0xFF76509A),
    Color(0xFFB34E72),
  ];
  static const eyeColors = <Color>[
    Color(0xFF30231F), Color(0xFF79513B), Color(0xFF9A7A42),
    Color(0xFF52755B), Color(0xFF527B9B), Color(0xFF71818B),
  ];
  static const hairStyles = [
    'Afro', 'Locs', 'Twists', 'Braids', 'Bantu knots', 'Curls',
    'Waves', 'Short crop', 'Bun', 'Ponytail', 'Bald',
  ];
  static const avatarKeys = ProfileService.avatarKeys;
  static const themeColors = <Color>[
    Color(0xFF355C3B), Color(0xFF9E6257), Color(0xFFB5873F),
    Color(0xFF426A78), Color(0xFF72617E), Color(0xFFAD7654),
    Color(0xFF485D83), Color(0xFF855A74), Color(0xFFBD735D),
    Color(0xFF567663), Color(0xFF397778), Color(0xFF967241),
  ];
  static const tabs = ['Gender', 'Skin', 'Hair', 'Face', 'Facial hair', 'Outfit'];
  static const presentations = ['Feminine', 'Masculine', 'Androgynous'];
  static const facialHairStyles = ['None', 'Stubble', 'Mustache', 'Goatee', 'Full beard'];
  static const faceShapes = ['Soft', 'Long', 'Round'];
  static const eyeStyles = ['Almond', 'Round', 'Gentle'];
  static const expressions = ['Smile', 'Big smile', 'Calm'];
  static const noseStyles = ['Soft', 'Straight', 'Wide'];
  static const browStyles = ['Natural', 'Bold', 'Soft arch'];
  static const moleOptions = ['None', 'Left cheek', 'Right cheek', 'Chin', 'Two moles'];
  static const glassesStyles = ['None', 'Square', 'Round'];
  static const freckleStyles = ['None', 'Light', 'More'];

  late int skin = widget.profile.avatarSkin.clamp(0, 11).toInt();
  late int hair = widget.profile.avatarHair.clamp(0, 10).toInt();
  late int hairColor = widget.profile.avatarHairColor.clamp(0, 9).toInt();
  late int face = widget.profile.avatarFace.clamp(0, 2).toInt();
  late int eyes = widget.profile.avatarEyes.clamp(0, 2).toInt();
  late int smile = widget.profile.avatarSmile.clamp(0, 2).toInt();
  late int presentation = widget.profile.avatarPresentation.clamp(0, 2).toInt();
  late int facialHair = widget.profile.avatarFacialHair.clamp(0, 4).toInt();
  late int mole = widget.profile.avatarMole.clamp(0, 4).toInt();
  late int nose = widget.profile.avatarNose.clamp(0, 2).toInt();
  late int brows = widget.profile.avatarBrows.clamp(0, 2).toInt();
  late int glasses = widget.profile.avatarGlasses.clamp(0, 2).toInt();
  late int freckles = widget.profile.avatarFreckles.clamp(0, 2).toInt();
  late int eyeColor = widget.profile.avatarEyeColor.clamp(0, 5).toInt();
  late String avatarKey = widget.profile.avatarKey;
  int activeTab = 0;
  bool saving = false;

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await ProfileService().updateAvatar(
        mode: 'avatar', key: avatarKey, skin: skin, hair: hair,
        hairColor: hairColor, face: face, eyes: eyes, smile: smile,
        presentation: presentation, facialHair: facialHair, mole: mole,
        nose: nose, brows: brows, glasses: glasses, freckles: freckles,
        eyeColor: eyeColor,
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

  void randomize() {
    final random = Random();
    setState(() {
      skin = random.nextInt(skinColors.length);
      hair = random.nextInt(hairStyles.length);
      hairColor = random.nextInt(hairColors.length);
      face = random.nextInt(3);
      eyes = random.nextInt(3);
      smile = random.nextInt(3);
      presentation = random.nextInt(3);
      facialHair = presentation == 0 ? 0 : random.nextInt(5);
      mole = random.nextInt(5);
      nose = random.nextInt(3);
      brows = random.nextInt(3);
      glasses = random.nextInt(3);
      freckles = random.nextInt(3);
      eyeColor = random.nextInt(6);
      avatarKey = avatarKeys[random.nextInt(avatarKeys.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        title: Text('Build your avatar', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          TextButton(onPressed: saving ? null : save, child: const Text('Save', style: TextStyle(color: sage, fontWeight: FontWeight.w800))),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                children: [
                  _preview(),
                  const SizedBox(height: 16),
                  _tabs(),
                  const SizedBox(height: 18),
                  _options(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              decoration: const BoxDecoration(color: cream, border: Border(top: BorderSide(color: line))),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving ? null : save,
                  style: FilledButton.styleFrom(backgroundColor: sage, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text(saving ? 'Saving…' : 'Save my avatar', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() => Container(
    height: 300,
    decoration: BoxDecoration(
      color: const Color(0xFFF2EEE4),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFE8E1D6)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(left: -30, top: -30, child: _orb(const Color(0xFFE1E8D9), 115)),
        Positioned(right: -22, bottom: -40, child: _orb(const Color(0xFFF1E1D5), 140)),
        Positioned(
          bottom: 27,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(190, 222),
              painter: _AvatarCharacterPainter(
                skin: skin,
                hair: hair,
                hairColor: hairColor,
                presentation: presentation,
                facialHair: facialHair,
                outfit: avatarKeys.indexOf(avatarKey).clamp(0, 11).toInt(),
                face: face,
                eyes: eyes,
                smile: smile,
                nose: nose,
                brows: brows,
                glasses: glasses,
                freckles: freckles,
                mole: mole,
                eyeColor: eyeColor,
              ),
            ),
          ),
        ),
        Positioned(
          top: 14, left: 16,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR LOOK', style: GoogleFonts.dmSans(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 3),
            Text('Make it feel like you.', style: GoogleFonts.playfairDisplay(color: ink, fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        ),
        Positioned(
          top: 12, right: 12,
          child: Material(
            color: Colors.white.withValues(alpha: .88),
            shape: const CircleBorder(),
            child: IconButton(tooltip: 'Randomize avatar', onPressed: randomize, icon: const Icon(Icons.casino_outlined, color: sage, size: 21)),
          ),
        ),
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Center(child: Text('Tap the categories below to customize', style: GoogleFonts.dmSans(color: muted, fontSize: 11, fontWeight: FontWeight.w600))),
        ),
      ],
    ),
  );

  Widget _orb(Color color, double size) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _tabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (var i = 0; i < tabs.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        ChoiceChip(
          label: Text(tabs[i]), selected: activeTab == i,
          onSelected: (_) => setState(() => activeTab = i),
          showCheckmark: false,
          labelStyle: TextStyle(color: activeTab == i ? Colors.white : ink, fontWeight: FontWeight.w700, fontSize: 12),
          selectedColor: sage, backgroundColor: Colors.white,
          side: BorderSide(color: activeTab == i ? sage : line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        ),
      ],
    ]),
  );

  Widget _options() => switch (activeTab) {
    0 => _genderOptions(),
    1 => _skinOptions(),
    2 => _hairOptions(),
    3 => _faceOptions(),
    4 => _facialHairOptions(),
    _ => _outfitOptions(),
  };

  Widget _genderOptions() => _optionPanel(
    'Gender expression', 'Choose the look that feels most like you.',
    Wrap(spacing: 9, runSpacing: 9, children: [
      for (var i = 0; i < presentations.length; i++) _selectCard(presentations[i], Icons.person_outline_rounded, presentation == i, () => setState(() {
        presentation = i;
        if (i == 0) facialHair = 0;
      })),
    ]),
  );

  Widget _skinOptions() => _optionPanel(
    'Skin tone', 'Choose from a range of natural tones.',
    Wrap(spacing: 13, runSpacing: 14, children: [
      for (var i = 0; i < skinColors.length; i++) _toneChoice(skinColors[i], skin == i, 'Skin tone ${i + 1}', () => setState(() => skin = i)),
    ]),
  );

  Widget _hairOptions() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _optionPanel('Hairstyle', 'Find the style that feels like you.', SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hairStyles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => setState(() => hair = i),
          child: Container(
            width: 76,
            padding: const EdgeInsets.fromLTRB(5, 7, 5, 5),
            decoration: BoxDecoration(color: hair == i ? const Color(0xFFEAF0E4) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: hair == i ? sage : line, width: hair == i ? 1.6 : 1)),
            child: Column(children: [
              Expanded(child: ClipOval(child: VillageAvatar(radius: 24, avatarMode: 'avatar', avatarKey: avatarKey, avatarSkin: skin, avatarHair: i, avatarHairColor: hairColor, avatarFace: face, avatarEyes: eyes, avatarSmile: smile, avatarPresentation: presentation, avatarFacialHair: facialHair, avatarMole: mole, avatarNose: nose, avatarBrows: brows, avatarGlasses: glasses, avatarFreckles: freckles, avatarEyeColor: eyeColor))),
              const SizedBox(height: 4),
              Text(hairStyles[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: hair == i ? sage : ink, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    )),
    const SizedBox(height: 15),
    _optionPanel('Hair colour', 'Make it natural or try something new.', Wrap(spacing: 12, runSpacing: 12, children: [
      for (var i = 0; i < hairColors.length; i++) _toneChoice(hairColors[i], hairColor == i, 'Hair colour ${i + 1}', () => setState(() => hairColor = i)),
    ])),
  ]);

  Widget _faceOptions() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _optionPanel('Face shape', 'A few small details make it yours.', _choiceRow(faceShapes, face, (v) => setState(() => face = v))),
    const SizedBox(height: 12),
    _optionPanel('Eyes & expression', 'Pick your eyes, eye colour, and smile.', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _choiceRow(eyeStyles, eyes, (v) => setState(() => eyes = v)),
      const SizedBox(height: 12),
      _miniLabel('Eye colour'),
      const SizedBox(height: 8),
      Wrap(spacing: 10, children: [for (var i = 0; i < eyeColors.length; i++) _toneChoice(eyeColors[i], eyeColor == i, 'Eye colour ${i + 1}', () => setState(() => eyeColor = i), size: 31)]),
      const SizedBox(height: 12),
      _choiceRow(expressions, smile, (v) => setState(() => smile = v)),
    ])),
    const SizedBox(height: 12),
    _optionPanel('Details', 'Add the little things people recognize.', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _miniLabel('Nose'), const SizedBox(height: 7), _choiceRow(noseStyles, nose, (v) => setState(() => nose = v)),
      const SizedBox(height: 12), _miniLabel('Eyebrows'), const SizedBox(height: 7), _choiceRow(browStyles, brows, (v) => setState(() => brows = v)),
      const SizedBox(height: 12), _miniLabel('Moles / beauty marks'), const SizedBox(height: 7), _choiceRow(moleOptions, mole, (v) => setState(() => mole = v)),
      const SizedBox(height: 12), _miniLabel('Freckles'), const SizedBox(height: 7), _choiceRow(freckleStyles, freckles, (v) => setState(() => freckles = v)),
      const SizedBox(height: 12), _miniLabel('Glasses'), const SizedBox(height: 7), _choiceRow(glassesStyles, glasses, (v) => setState(() => glasses = v)),
    ])),
  ]);

  Widget _facialHairOptions() => _optionPanel(
    'Facial hair', 'Choose any style—or none at all.',
    Wrap(spacing: 9, runSpacing: 9, children: [
      for (var i = 0; i < facialHairStyles.length; i++) _selectCard(facialHairStyles[i], Icons.face_rounded, facialHair == i, () => setState(() => facialHair = i)),
    ]),
  );

  Widget _outfitOptions() => _optionPanel(
    'Outfit colour', 'Choose the colour your avatar wears.',
    Wrap(spacing: 13, runSpacing: 14, children: [
      for (var i = 0; i < avatarKeys.length; i++) _themeChoice(i),
    ]),
  );

  Widget _themeChoice(int index) {
    final selected = avatarKey == avatarKeys[index];
    return Semantics(
      label: '${avatarKeys[index]} outfit colour', selected: selected, button: true,
      child: GestureDetector(
        onTap: () => setState(() => avatarKey = avatarKeys[index]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(shape: BoxShape.circle, color: themeColors[index], border: Border.all(color: selected ? sage : Colors.white, width: selected ? 3 : 2), boxShadow: selected ? const [BoxShadow(color: Color(0x22000000), blurRadius: 5)] : null), child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null),
          const SizedBox(height: 5),
          Text(avatarKeys[index][0].toUpperCase() + avatarKeys[index].substring(1), style: TextStyle(color: selected ? sage : muted, fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _optionPanel(String title, String subtitle, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.playfairDisplay(color: ink, fontSize: 19, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(subtitle, style: GoogleFonts.dmSans(color: muted, fontSize: 12)),
      const SizedBox(height: 14),
      child,
    ]),
  );

  Widget _choiceRow(List<String> labels, int selected, ValueChanged<int> onSelect) => Wrap(spacing: 7, runSpacing: 7, children: [
    for (var i = 0; i < labels.length; i++) ChoiceChip(
      label: Text(labels[i]), selected: selected == i, onSelected: (_) => onSelect(i), showCheckmark: false,
      labelStyle: TextStyle(fontSize: 11, color: selected == i ? sage : ink, fontWeight: FontWeight.w700),
      selectedColor: const Color(0xFFEAF0E4), backgroundColor: cream,
      side: BorderSide(color: selected == i ? sage : line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 3),
    ),
  ]);

  Widget _selectCard(String label, IconData icon, bool selected, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 100, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(color: selected ? const Color(0xFFEAF0E4) : cream, borderRadius: BorderRadius.circular(15), border: Border.all(color: selected ? sage : line, width: selected ? 1.5 : 1)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: selected ? sage : muted, size: 23), const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: selected ? sage : ink, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ),
  );

  Widget _toneChoice(Color color, bool selected, String label, VoidCallback onTap, {double size = 39}) => Semantics(
    label: label, selected: selected, button: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: selected ? sage : Colors.white, width: selected ? 3 : 2), boxShadow: selected ? const [BoxShadow(color: Color(0x22000000), blurRadius: 4)] : null),
        child: selected ? Icon(Icons.check_rounded, color: Colors.white, size: size * .45) : null,
      ),
    ),
  );

  Widget _miniLabel(String text) => Text(text, style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700));
}

class _AvatarCharacterPainter extends CustomPainter {
  const _AvatarCharacterPainter({
    required this.skin,
    required this.hair,
    required this.hairColor,
    required this.presentation,
    required this.facialHair,
    required this.outfit,
    required this.face,
    required this.eyes,
    required this.smile,
    required this.nose,
    required this.brows,
    required this.glasses,
    required this.freckles,
    required this.mole,
    required this.eyeColor,
  });

  final int skin;
  final int hair;
  final int hairColor;
  final int presentation;
  final int facialHair;
  final int outfit;
  final int face;
  final int eyes;
  final int smile;
  final int nose;
  final int brows;
  final int glasses;
  final int freckles;
  final int mole;
  final int eyeColor;

  static const _skinTones = <Color>[
    Color(0xFF3B2119), Color(0xFF563326), Color(0xFF704630),
    Color(0xFF81513D), Color(0xFF8B553A), Color(0xFF9C6045),
    Color(0xFFA66A4E), Color(0xFFB97855), Color(0xFFC98761),
    Color(0xFFD69A70), Color(0xFFE0AD86), Color(0xFFEDC29B),
  ];
  static const _hairTones = <Color>[
    Color(0xFF171311), Color(0xFF2D211C), Color(0xFF542F23),
    Color(0xFF8A5837), Color(0xFFC17C36), Color(0xFFE1BE78),
    Color(0xFF4A4A47), Color(0xFFE1D9CC), Color(0xFF76509A),
    Color(0xFFB34E72),
  ];
  static const _outfitTones = <Color>[
    Color(0xFF355C3B), Color(0xFF9E6257), Color(0xFFB5873F),
    Color(0xFF426A78), Color(0xFF72617E), Color(0xFFAD7654),
    Color(0xFF485D83), Color(0xFF855A74), Color(0xFFBD735D),
    Color(0xFF567663), Color(0xFF397778), Color(0xFF967241),
  ];
  static const _eyeTones = <Color>[
    Color(0xFF30231F), Color(0xFF79513B), Color(0xFF9A7A42),
    Color(0xFF52755B), Color(0xFF527B9B), Color(0xFF71818B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 190, size.height / 222);
    final skinTone = _skinTones[skin.clamp(0, 11).toInt()];
    final hairTone = _hairTones[hairColor.clamp(0, 9).toInt()];
    final outfitTone = _outfitTones[outfit.clamp(0, 11).toInt()];
    final dark = const Color(0xFF30231F);
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Soft grounding shadow and feet.
    fill.color = const Color(0x1E30231F);
    canvas.drawOval(const Rect.fromLTWH(47, 205, 96, 13), fill);
    fill.color = const Color(0xFF51443B);
    canvas.drawOval(const Rect.fromLTWH(61, 199, 26, 12), fill);
    canvas.drawOval(const Rect.fromLTWH(105, 199, 26, 12), fill);

    // Back hair gives long styles room to fall behind the shoulders.
    fill.color = hairTone;
    if (hair == 1 || hair == 2 || hair == 3 || hair == 9) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(67, 39, 56, 93), const Radius.circular(27)), fill);
      if (hair == 1 || hair == 2 || hair == 3) {
        for (var x = 72.0; x <= 116; x += hair == 3 ? 7 : 10) {
          final width = hair == 3 ? 4.2 : 6.5;
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 72, width, 47 + (x.toInt() % 3) * 4), Radius.circular(width / 2)), fill);
        }
      } else {
        canvas.drawOval(const Rect.fromLTWH(116, 50, 31, 58), fill);
      }
    }

    // Legs / lower half. Feminine presentation uses a soft A-line outfit;
    // masculine and androgynous looks use separate trousers.
    if (presentation == 0) {
      final skirt = Path()
        ..moveTo(68, 137)
        ..lineTo(122, 137)
        ..quadraticBezierTo(132, 163, 140, 195)
        ..lineTo(50, 195)
        ..quadraticBezierTo(58, 163, 68, 137)
        ..close();
      fill.color = outfitTone;
      canvas.drawPath(skirt, fill);
      fill.color = skinTone;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 182, 13, 22), const Radius.circular(6)), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(105, 182, 13, 22), const Radius.circular(6)), fill);
    } else {
      fill.color = Color.lerp(outfitTone, dark, .3)!;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(68, 137, 25, 65), const Radius.circular(9)), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(97, 137, 25, 65), const Radius.circular(9)), fill);
    }

    // Neck, arms, and shirt / dress bodice.
    fill.color = skinTone;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(84, 94, 22, 31), const Radius.circular(9)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(53, 108, 15, 67), const Radius.circular(8)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(122, 108, 15, 67), const Radius.circular(8)), fill);
    fill.color = outfitTone;
    final top = Path()
      ..moveTo(77, 111)
      ..quadraticBezierTo(82, 104, 88, 103)
      ..lineTo(95, 110)
      ..lineTo(102, 103)
      ..quadraticBezierTo(111, 104, 116, 111)
      ..lineTo(126, 140)
      ..quadraticBezierTo(96, 151, 66, 140)
      ..close();
    canvas.drawPath(top, fill);
    // Shirt neckline and seams add a little clothing detail.
    stroke.color = Color.lerp(outfitTone, Colors.white, .35)!;
    stroke.strokeWidth = 2;
    canvas.drawArc(const Rect.fromLTWH(83, 101, 24, 18), .2, 2.75, false, stroke);

    // Hair cap and style-specific silhouette.
    fill.color = hairTone;
    switch (hair) {
      case 0: // Afro
        canvas.drawOval(const Rect.fromLTWH(57, 20, 76, 55), fill);
        for (final p in const [Offset(63, 38), Offset(72, 24), Offset(86, 18), Offset(101, 18), Offset(118, 27), Offset(128, 43), Offset(60, 54), Offset(130, 55)]) {
          canvas.drawCircle(p, 12, fill);
        }
        break;
      case 1: // Locs
      case 2: // Twists
      case 3: // Braids
        canvas.drawOval(const Rect.fromLTWH(68, 25, 54, 46), fill);
        break;
      case 4: // Bantu knots
        canvas.drawOval(const Rect.fromLTWH(68, 41, 54, 29), fill);
        for (final p in const [Offset(71, 37), Offset(82, 25), Offset(95, 21), Offset(108, 25), Offset(120, 37)]) {
          canvas.drawCircle(p, 7, fill);
        }
        break;
      case 5: // Curls
        canvas.drawOval(const Rect.fromLTWH(64, 27, 62, 47), fill);
        for (final p in const [Offset(69, 43), Offset(79, 30), Offset(94, 26), Offset(109, 32), Offset(120, 45)]) {
          canvas.drawCircle(p, 8, fill);
        }
        break;
      case 6: // Waves
        canvas.drawOval(const Rect.fromLTWH(68, 25, 54, 45), fill);
        final wave = Path()
          ..moveTo(67, 57)
          ..quadraticBezierTo(79, 38, 91, 53)
          ..quadraticBezierTo(105, 36, 123, 54)
          ..lineTo(120, 65)
          ..quadraticBezierTo(96, 52, 70, 67)
          ..close();
        canvas.drawPath(wave, fill);
        break;
      case 7: // Short crop
        canvas.drawOval(const Rect.fromLTWH(70, 26, 50, 32), fill);
        break;
      case 8: // Bun
        canvas.drawOval(const Rect.fromLTWH(68, 28, 54, 44), fill);
        canvas.drawCircle(const Offset(96, 19), 13, fill);
        break;
      case 9: // Ponytail
        canvas.drawOval(const Rect.fromLTWH(68, 26, 54, 44), fill);
        break;
      case 10: // Bald
        break;
    }
    if (hair == 1 || hair == 2 || hair == 3) {
      for (var x = 72.0; x <= 116; x += hair == 3 ? 7 : 10) {
        final width = hair == 3 ? 4.2 : 6.5;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 53, width, 39 + (x.toInt() % 3) * 3), Radius.circular(width / 2)), fill);
      }
    } else if (hair == 9) {
      canvas.drawOval(const Rect.fromLTWH(112, 48, 29, 54), fill);
    }

    // Face silhouette and ears are painted over the hair cap, keeping the
    // hairline visible while leaving the face clear for its chosen features.
    fill.color = skinTone;
    canvas.drawOval(const Rect.fromLTWH(65, 45, 16, 23), fill);
    canvas.drawOval(const Rect.fromLTWH(109, 45, 16, 23), fill);
    final faceWidth = presentation == 0 ? 50.0 : presentation == 1 ? 54.0 : 52.0;
    final faceRect = Rect.fromCenter(center: const Offset(95, 65), width: faceWidth, height: face == 1 ? 68 : face == 2 ? 58 : 64);
    canvas.drawRRect(RRect.fromRectAndRadius(faceRect, Radius.circular(presentation == 0 ? 23 : 20)), fill);

    // Face details. A feminine style has a softer jaw, lifted eyes, and a
    // gentle lip shape so changing the selection is immediately visible.
    final eyeY = presentation == 0 ? 61.0 : 62.0;
    fill.color = _eyeTones[eyeColor.clamp(0, 5).toInt()];
    canvas.drawOval(Rect.fromCenter(center: Offset(84, eyeY), width: 5, height: eyes == 1 ? 5 : 3.5), fill);
    canvas.drawOval(Rect.fromCenter(center: Offset(106, eyeY), width: 5, height: eyes == 1 ? 5 : 3.5), fill);
    stroke.color = hairTone;
    stroke.strokeWidth = brows == 1 ? 3.2 : brows == 2 ? 1.5 : 2.2;
    canvas.drawLine(Offset(78, eyeY - 7), Offset(88, eyeY - 8), stroke);
    canvas.drawLine(Offset(102, eyeY - 8), Offset(112, eyeY - 7), stroke);
    if (presentation == 0) {
      stroke.strokeWidth = 1.2;
      canvas.drawLine(Offset(81, eyeY - 2), Offset(79, eyeY - 5), stroke);
      canvas.drawLine(Offset(109, eyeY - 2), Offset(111, eyeY - 5), stroke);
    }
    stroke.color = Color.lerp(dark, skinTone, .18)!;
    stroke.strokeWidth = nose == 2 ? 2.1 : 1.4;
    canvas.drawLine(const Offset(95, 64), Offset(95 + (nose - 1) * 2.0, 73), stroke);
    stroke.color = presentation == 0 ? const Color(0xFF9E5B60) : const Color(0xFF8B4C46);
    stroke.strokeWidth = presentation == 0 ? 2.5 : 2;
    final mouth = Path()
      ..moveTo(89, 81)
      ..quadraticBezierTo(95, smile == 1 ? 88 : 85, 101, 81);
    if (smile == 2) {
      canvas.drawLine(const Offset(90, 82), const Offset(100, 82), stroke);
    } else {
      canvas.drawPath(mouth, stroke);
    }

    if (facialHair > 0) {
      fill.color = hairTone;
      if (facialHair == 1) {
        for (final p in const [Offset(83, 80), Offset(88, 84), Offset(95, 85), Offset(102, 84), Offset(107, 80)]) {
          canvas.drawCircle(p, 1.3, fill);
        }
      } else if (facialHair == 2 || facialHair == 3) {
        canvas.drawOval(const Rect.fromLTWH(88, 77, 7, 4), fill);
        canvas.drawOval(const Rect.fromLTWH(95, 77, 7, 4), fill);
        if (facialHair == 3) canvas.drawOval(const Rect.fromLTWH(91, 84, 9, 7), fill);
      } else {
        final beard = Path()
          ..moveTo(73, 67)
          ..quadraticBezierTo(74, 93, 95, 101)
          ..quadraticBezierTo(116, 93, 117, 67)
          ..quadraticBezierTo(108, 83, 95, 82)
          ..quadraticBezierTo(82, 83, 73, 67)
          ..close();
        canvas.drawPath(beard, fill);
        fill.color = skinTone;
        canvas.drawOval(const Rect.fromLTWH(89, 79, 13, 7), fill);
      }
    }

    if (freckles > 0) {
      fill.color = Color.lerp(dark, skinTone, .4)!;
      for (final p in const [Offset(78, 72), Offset(83, 74), Offset(88, 72), Offset(102, 72), Offset(107, 74), Offset(112, 72)]) {
        canvas.drawCircle(p, freckles == 1 ? 1.0 : 1.5, fill);
      }
    }
    if (mole > 0) {
      fill.color = const Color(0xFF4D3027);
      final point = switch (mole) {
        1 => const Offset(81, 75),
        2 => const Offset(109, 75),
        3 => const Offset(95, 91),
        _ => const Offset(81, 75),
      };
      canvas.drawCircle(point, 1.6, fill);
      if (mole == 4) canvas.drawCircle(const Offset(109, 75), 1.6, fill);
    }
    if (glasses > 0) {
      stroke.color = const Color(0xFF51413B);
      stroke.strokeWidth = 1.8;
      final radius = glasses == 1 ? const Radius.circular(3) : const Radius.circular(8);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(75, 55, 19, 15), radius), stroke);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(96, 55, 19, 15), radius), stroke);
      canvas.drawLine(const Offset(94, 61), const Offset(96, 61), stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarCharacterPainter oldDelegate) =>
      skin != oldDelegate.skin || hair != oldDelegate.hair ||
      hairColor != oldDelegate.hairColor || presentation != oldDelegate.presentation ||
      facialHair != oldDelegate.facialHair || outfit != oldDelegate.outfit ||
      face != oldDelegate.face || eyes != oldDelegate.eyes || smile != oldDelegate.smile ||
      nose != oldDelegate.nose || brows != oldDelegate.brows || glasses != oldDelegate.glasses ||
      freckles != oldDelegate.freckles || mole != oldDelegate.mole || eyeColor != oldDelegate.eyeColor;
}
