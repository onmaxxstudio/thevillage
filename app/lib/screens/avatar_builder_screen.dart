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
  static const tabs = ['Skin tone', 'Hairstyle', 'Features', 'More'];
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            _preview(),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 14),
            _options(),
          ],
        ),
      ),
    );
  }

  Widget _preview() => Container(
    height: 330,
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
          bottom: 25,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(240, 190),
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
          child: Center(child: Text('Your portrait updates as you customize', style: GoogleFonts.dmSans(color: muted, fontSize: 11, fontWeight: FontWeight.w600))),
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
  const _AvatarCharacterPainter({required this.skin,required this.hair,required this.hairColor,required this.presentation,required this.facialHair,required this.outfit,required this.face,required this.eyes,required this.smile,required this.nose,required this.brows,required this.glasses,required this.freckles,required this.mole,required this.eyeColor});
  final int skin,hair,hairColor,presentation,facialHair,outfit,face,eyes,smile,nose,brows,glasses,freckles,mole,eyeColor;
  static const skins=[Color(0xFF3B2119),Color(0xFF563326),Color(0xFF704630),Color(0xFF81513D),Color(0xFF8B553A),Color(0xFF9C6045),Color(0xFFA66A4E),Color(0xFFB97855),Color(0xFFC98761),Color(0xFFD69A70),Color(0xFFE0AD86),Color(0xFFEDC29B)];
  static const hairs=[Color(0xFF171311),Color(0xFF2D211C),Color(0xFF542F23),Color(0xFF8A5837),Color(0xFFC17C36),Color(0xFFE1BE78),Color(0xFF4A4A47),Color(0xFFE1D9CC),Color(0xFF76509A),Color(0xFFB34E72)];
  static const outfits=[Color(0xFF355C3B),Color(0xFF9E6257),Color(0xFFB5873F),Color(0xFF426A78),Color(0xFF72617E),Color(0xFFAD7654),Color(0xFF485D83),Color(0xFF855A74),Color(0xFFBD735D),Color(0xFF567663),Color(0xFF397778),Color(0xFF967241)];
  static const eyesC=[Color(0xFF30231F),Color(0xFF79513B),Color(0xFF9A7A42),Color(0xFF52755B),Color(0xFF527B9B),Color(0xFF71818B)];
  @override void paint(Canvas canvas,Size size){
    canvas.save(); canvas.scale(size.width/190,size.width/190); canvas.clipRect(const Rect.fromLTWH(0,0,190,150));
    final s=skins[skin.clamp(0,11)], h=hairs[hairColor.clamp(0,9)], shirt=outfits[outfit.clamp(0,11)];
    final p=Paint()..style=PaintingStyle.fill; final line=Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=2;
    // Soft portrait backdrop and shoulders.
    p.color=const Color(0xFFE9EDE3); canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14,5,162,145),const Radius.circular(72)),p);
    p.color=s; canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(77,88,36,35),const Radius.circular(15)),p);
    p.color=shirt; final shoulders=Path()..moveTo(77,105)..lineTo(95,116)..lineTo(113,105)..quadraticBezierTo(153,109,164,150)..lineTo(26,150)..quadraticBezierTo(37,109,77,105)..close(); canvas.drawPath(shoulders,p);
    // Hair behind face; locks fall to shoulder line.
    p.color=h;
    if([1,2,3,9].contains(hair)){canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52,35,86,92),const Radius.circular(38)),p); if([1,2,3].contains(hair)){for(double x=57;x<137;x+=hair==3?8:12){canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,67, hair==3?5:8,54+(x.toInt()%2)*8),const Radius.circular(5)),p);}}}
    // Hair silhouette variations.
    if(hair==0){canvas.drawOval(const Rect.fromLTWH(43,14,104,78),p); for(final q in const [Offset(50,41),Offset(62,23),Offset(80,16),Offset(102,15),Offset(125,24),Offset(140,44),Offset(49,64),Offset(139,64)]) canvas.drawCircle(q,15,p);}
    else if(hair==4){canvas.drawOval(const Rect.fromLTWH(55,28,80,60),p); for(final q in const [Offset(60,38),Offset(76,24),Offset(95,20),Offset(115,24),Offset(132,39)]) canvas.drawCircle(q,9,p);}
    else if(hair==5||hair==6||hair==8||hair==9){canvas.drawOval(const Rect.fromLTWH(53,23,84,65),p); if(hair==8)canvas.drawCircle(const Offset(96,17),17,p); if(hair==9)canvas.drawOval(const Rect.fromLTWH(127,43,32,74),p);}
    else if(hair==7){canvas.drawOval(const Rect.fromLTWH(59,25,72,43),p);}
    // Ears and softly shaped face.
    p.color=s; canvas.drawOval(const Rect.fromLTWH(50,51,20,29),p); canvas.drawOval(const Rect.fromLTWH(120,51,20,29),p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(61,35,68,77), const Radius.circular(30)),p);
    // Face is drawn over the hairline for a clean portrait silhouette.
    p.color=s; canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(61,36,68,76),const Radius.circular(31)),p);
    // Eyes, brows, nose, blush and mouth.
    final ey=70.0; p.color=const Color(0xFFFFF8EF); canvas.drawOval(Rect.fromCenter(center:Offset(79,ey),width:15,height:eyes==1?9:7),p); canvas.drawOval(Rect.fromCenter(center:Offset(111,ey),width:15,height:eyes==1?9:7),p);
    p.color=eyesC[eyeColor.clamp(0,5)]; canvas.drawCircle(Offset(79,ey),3.6,p); canvas.drawCircle(Offset(111,ey),3.6,p); p.color=const Color(0xFF30231F); canvas.drawCircle(Offset(79,ey),1.8,p); canvas.drawCircle(Offset(111,ey),1.8,p);
    line.color=h; line.strokeWidth=brows==1?3.5:2.4; canvas.drawLine(const Offset(70,59),const Offset(87,57),line); canvas.drawLine(const Offset(103,57),const Offset(120,59),line);
    p.color=Color.lerp(const Color(0xFFB56F54),s,.55)!; canvas.drawOval(Rect.fromCenter(center:Offset(95,83),width:nose==2?9:6,height:5),p);
    p.color=Color.lerp(const Color(0xFFE79D8E),s,.72)!; canvas.drawOval(const Rect.fromLTWH(67,81,16,7),p); canvas.drawOval(const Rect.fromLTWH(107,81,16,7),p);
    line.color=const Color(0xFF985B59); line.strokeWidth=3; final mouth=Path()..moveTo(84,96)..quadraticBezierTo(95,smile==1?106:101,106,96); if(smile==2)canvas.drawLine(const Offset(85,98),const Offset(105,98),line);else canvas.drawPath(mouth,line);
    if(facialHair>0){p.color=h;if(facialHair==1){for(final q in const [Offset(80,99),Offset(88,103),Offset(96,104),Offset(104,103),Offset(112,99)])canvas.drawCircle(q,1.8,p);}else{canvas.drawOval(const Rect.fromLTWH(82,97,13,8),p);canvas.drawOval(const Rect.fromLTWH(96,97,13,8),p); if(facialHair>=3)canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(83,99,25,20),const Radius.circular(10)),p);}}
    if(freckles>0){p.color=Color.lerp(const Color(0xFF30231F),s,.45)!;for(final q in const [Offset(73,85),Offset(80,88),Offset(87,85),Offset(103,85),Offset(110,88),Offset(117,85)])canvas.drawCircle(q,freckles==1?1.2:1.8,p);}
    if(mole>0){p.color=const Color(0xFF4D3027);final q=mole==1?const Offset(75,91):mole==2?const Offset(115,91):mole==3?const Offset(95,107):const Offset(75,91);canvas.drawCircle(q,2,p);if(mole==4)canvas.drawCircle(const Offset(115,91),2,p);}
    if(glasses>0){line.color=const Color(0xFF51413B);line.strokeWidth=2;final r=glasses==1?const Radius.circular(4):const Radius.circular(10);canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66,62,27,20),r),line);canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(98,62,27,20),r),line);canvas.drawLine(const Offset(93,71),const Offset(98,71),line);}
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _AvatarCharacterPainter old)=>skin!=old.skin||hair!=old.hair||hairColor!=old.hairColor||presentation!=old.presentation||facialHair!=old.facialHair||outfit!=old.outfit||face!=old.face||eyes!=old.eyes||smile!=old.smile||nose!=old.nose||brows!=old.brows||glasses!=old.glasses||freckles!=old.freckles||mole!=old.mole||eyeColor!=old.eyeColor;
}
