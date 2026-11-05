import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/profile_service.dart';
import '../widgets/village_avatar.dart';
import '../widgets/village_portrait.dart';

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
    Color(0xFF3B2119),
    Color(0xFF563326),
    Color(0xFF704630),
    Color(0xFF81513D),
    Color(0xFF8B553A),
    Color(0xFF9C6045),
    Color(0xFFA66A4E),
    Color(0xFFB97855),
    Color(0xFFC98761),
    Color(0xFFD69A70),
    Color(0xFFE0AD86),
    Color(0xFFEDC29B),
    Color(0xFFF2D3C3),
    Color(0xFFF8E4DC),
  ];
  static const hairColors = <Color>[
    Color(0xFF171311),
    Color(0xFF2D211C),
    Color(0xFF542F23),
    Color(0xFF8A5837),
    Color(0xFFC17C36),
    Color(0xFFE1BE78),
    Color(0xFFB8BAC1),
    Color(0xFFF3F2EE),
    Color(0xFF76509A),
    Color(0xFFB34E72),
  ];
  static const eyeColors = <Color>[
    Color(0xFF30231F),
    Color(0xFF79513B),
    Color(0xFF9A7A42),
    Color(0xFF52755B),
    Color(0xFF527B9B),
    Color(0xFF71818B),
  ];
  static const hairStyles = [
    'Afro',
    'Locs',
    'Twists',
    'Braids',
    'Bantu knots',
    'Curls',
    'Waves',
    'Short crop',
    'Bun',
    'Ponytail',
    'Bald',
    'Straight bob',
    'Side part',
    'Long straight',
    'Loose waves',
    'Textured fringe',
    'Curtain layers',
  ];
  // These lists reference saved hairstyle IDs, independently of picker order.
  static const hairstylesByPresentation = [
    [8, 9, 11, 13, 14, 16, 5, 4, 0, 1, 2, 3, 6, 10],
    [7, 12, 15, 0, 1, 2, 3, 6, 10],
    [1, 7, 12, 2, 3, 0, 4, 5, 6, 8, 9, 10, 11, 13, 14, 15, 16],
  ];
  List<int> get availableHairstyles => hairstylesByPresentation[presentation];

  static const avatarKeys = ProfileService.avatarKeys;
  static const themeColors = <Color>[
    Color(0xFF355C3B),
    Color(0xFF9E6257),
    Color(0xFFB5873F),
    Color(0xFF426A78),
    Color(0xFF72617E),
    Color(0xFFAD7654),
    Color(0xFF485D83),
    Color(0xFF855A74),
    Color(0xFFBD735D),
    Color(0xFF567663),
    Color(0xFF397778),
    Color(0xFF967241),
  ];
  static const tabs = [
    'Your Base',
    'Skin Tone',
    'Hairstyle',
    'Features',
    'Accessories',
  ];
  static const presentations = ['Feminine', 'Masculine', 'Androgynous'];
  static const facialHairStyles = [
    'None',
    'Stubble',
    'Mustache',
    'Goatee',
    'Full beard',
  ];
  static const faceShapes = ['Soft', 'Long', 'Round'];
  static const eyeStyles = ['Almond', 'Round', 'Gentle'];
  static const expressions = ['Smile', 'Big smile', 'Calm'];
  static const noseStyles = ['Soft', 'Straight', 'Wide'];
  static const browStyles = ['Natural', 'Bold', 'Soft arch'];
  static const moleOptions = [
    'None',
    'Left cheek',
    'Right cheek',
    'Chin',
    'Two moles',
  ];
  static const glassesStyles = ['None', 'Square', 'Round'];
  static const freckleStyles = ['None', 'Light', 'More'];

  late int skin = widget.profile.avatarSkin.clamp(0, skinColors.length - 1).toInt();
  late int hair = widget.profile.avatarHair.clamp(0, hairStyles.length - 1).toInt();
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
        mode: 'avatar',
        key: avatarKey,
        skin: skin,
        hair: hair,
        hairColor: hairColor,
        face: face,
        eyes: eyes,
        smile: smile,
        presentation: presentation,
        facialHair: facialHair,
        mole: mole,
        nose: nose,
        brows: brows,
        glasses: glasses,
        freckles: freckles,
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
      hairColor = random.nextInt(hairColors.length);
      face = random.nextInt(3);
      eyes = random.nextInt(3);
      smile = random.nextInt(3);
      presentation = random.nextInt(hairstylesByPresentation.length);
      hair = availableHairstyles[random.nextInt(availableHairstyles.length)];
      facialHair = random.nextInt(5);
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
        title: Text(
          'Create Your Character',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: sage),
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving…' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
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
        ),
      ),
    );
  }

  Widget _portrait({int? hairstyle}) => VillagePortrait(
    skin: skin,
    hair: hairstyle ?? hair,
    hairColor: hairColor,
    presentation: presentation,
    facialHair: facialHair,
    outfit: avatarKeys.indexOf(avatarKey).clamp(0, 11),
    face: face,
    eyes: eyes,
    smile: smile,
    nose: nose,
    brows: brows,
    glasses: glasses,
    freckles: freckles,
    mole: mole,
    eyeColor: eyeColor,
  );

  Widget _preview() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = (width * .55).clamp(234.0, 420.0);
      return Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF7F2E8), Color(0xFFE4E9D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Stack(
          children: [
            Positioned(
              right: width < 430 ? -height * .12 : width * .12,
              bottom: 0,
              width: height,
              height: height,
              child: _portrait(),
            ),
            Positioned(
              left: width * .05,
              top: height * .19,
              width: width * .37,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR CHARACTER',
                    style: GoogleFonts.dmSans(
                      color: sage,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your look.\nYour way.',
                    style: GoogleFonts.playfairDisplay(
                      color: ink,
                      fontSize: (width * .062).clamp(19.0, 45.0),
                      fontWeight: FontWeight.w800,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create an avatar that represents you in the Village.',
                    style: GoogleFonts.dmSans(
                      color: ink,
                      fontSize: width < 430 ? 11 : 15,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                children: [
                  _previewAction(
                    'Randomize avatar',
                    Icons.shuffle_rounded,
                    randomize,
                  ),
                  const SizedBox(height: 5),
                  _previewAction('Enlarge avatar', Icons.fullscreen, () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => Dialog(
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _portrait(),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: _previewAction(
                                    'Close preview',
                                    Icons.close,
                                    () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _previewAction(
    String tooltip,
    IconData icon,
    VoidCallback onPressed,
  ) => Material(
    color: cream,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: sage),
    ),
  );

  Widget _tabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          ChoiceChip(
            label: Text(tabs[i]),
            selected: activeTab == i,
            onSelected: (_) => setState(() => activeTab = i),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: activeTab == i ? Colors.white : ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            selectedColor: sage,
            backgroundColor: Colors.white,
            side: BorderSide(color: activeTab == i ? sage : line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          ),
        ],
      ],
    ),
  );

  Widget _options() => switch (activeTab) {
    0 => _genderOptions(),
    1 => _skinOptions(),
    2 => _hairOptions(),
    3 => _faceOptions(),
    _ => Column(
      children: [
        _facialHairOptions(),
        const SizedBox(height: 12),
        _outfitOptions(),
      ],
    ),
  };

  Widget _genderOptions() => _optionPanel(
    'Choose Your Starting Character',
    'Pick a starting look, then customize every detail to make it yours.',
    LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = ((constraints.maxWidth - 16) / 3).clamp(72.0, 255.0);
        return Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (var i = 0; i < presentations.length; i++)
              Semantics(
                label: '${presentations[i]} starting character',
                selected: presentation == i,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    presentation = i;
                    if (i == 0) {
                      hair = 8;
                      facialHair = 0;
                      glasses = 0;
                      face = 0;
                    }
                    if (i == 1) {
                      hair = 7;
                      facialHair = 4;
                      glasses = 0;
                      face = 0;
                    }
                    if (i == 2) {
                      hair = 1;
                      facialHair = 0;
                      glasses = 1;
                      face = 0;
                    }
                  }),
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.fromLTRB(5, 8, 5, 10),
                    decoration: BoxDecoration(
                      color: presentation == i
                          ? const Color(0xFFEAF0E4)
                          : cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: presentation == i ? sage : line,
                        width: presentation == i ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: VillagePortrait.starter(i),
                          ),
                        ),
                        const SizedBox(height: 7),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            presentations[i],
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: presentation == i ? sage : ink,
                            ),
                          ),
                        ),
                        if (presentation == i)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: sage,
                            size: 17,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _skinOptions() => _optionPanel(
    'Skin tone',
    'Choose from a range of natural tones.',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _choiceRow(const ['Fair', 'Very fair'], skin - 12, (value) {
          setState(() => skin = 12 + value);
        }),
        const SizedBox(height: 12),
        Wrap(
          spacing: 13,
          runSpacing: 14,
          children: [
            for (var i = 0; i < 12; i++)
              _toneChoice(
                skinColors[i],
                skin == i,
                'Skin tone ${i + 1}',
                () => setState(() => skin = i),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _hairOptions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _optionPanel(
        'Hairstyle',
        'Find the style that feels like you.',
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: availableHairstyles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final i = availableHairstyles[index];
              return GestureDetector(
                onTap: () => setState(() => hair = i),
                child: Container(
                  width: 76,
                  padding: const EdgeInsets.fromLTRB(5, 7, 5, 5),
                  decoration: BoxDecoration(
                    color: hair == i ? const Color(0xFFEAF0E4) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: hair == i ? sage : line,
                      width: hair == i ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: ClipOval(child: _portrait(hairstyle: i)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hairStyles[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: hair == i ? sage : ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 15),
      _optionPanel(
        'Hair colour',
        'Make it natural or try something new.',
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < hairColors.length; i++)
              _toneChoice(
                hairColors[i],
                hairColor == i,
                switch (i) {
                  6 => 'Silver',
                  7 => 'White',
                  _ => 'Hair colour ${i + 1}',
                },
                () => setState(() => hairColor = i),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _faceOptions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _optionPanel(
        'Face shape',
        'A few small details make it yours.',
        _choiceRow(faceShapes, face, (v) => setState(() => face = v)),
      ),
      const SizedBox(height: 12),
      _optionPanel(
        'Eyes & expression',
        'Pick your eyes, eye colour, and smile.',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _choiceRow(eyeStyles, eyes, (v) => setState(() => eyes = v)),
            const SizedBox(height: 12),
            _miniLabel('Eye colour'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (var i = 0; i < eyeColors.length; i++)
                  _toneChoice(
                    eyeColors[i],
                    eyeColor == i,
                    'Eye colour ${i + 1}',
                    () => setState(() => eyeColor = i),
                    size: 31,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _choiceRow(expressions, smile, (v) => setState(() => smile = v)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _optionPanel(
        'Details',
        'Add the little things people recognize.',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _miniLabel('Nose'),
            const SizedBox(height: 7),
            _choiceRow(noseStyles, nose, (v) => setState(() => nose = v)),
            const SizedBox(height: 12),
            _miniLabel('Eyebrows'),
            const SizedBox(height: 7),
            _choiceRow(browStyles, brows, (v) => setState(() => brows = v)),
            const SizedBox(height: 12),
            _miniLabel('Moles / beauty marks'),
            const SizedBox(height: 7),
            _choiceRow(moleOptions, mole, (v) => setState(() => mole = v)),
            const SizedBox(height: 12),
            _miniLabel('Freckles'),
            const SizedBox(height: 7),
            _choiceRow(
              freckleStyles,
              freckles,
              (v) => setState(() => freckles = v),
            ),
            const SizedBox(height: 12),
            _miniLabel('Glasses'),
            const SizedBox(height: 7),
            _choiceRow(
              glassesStyles,
              glasses,
              (v) => setState(() => glasses = v),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _facialHairOptions() => _optionPanel(
    'Facial hair',
    'Choose any style—or none at all.',
    Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        for (var i = 0; i < facialHairStyles.length; i++)
          _selectCard(
            facialHairStyles[i],
            Icons.face_rounded,
            facialHair == i,
            () => setState(() => facialHair = i),
          ),
      ],
    ),
  );

  Widget _outfitOptions() => _optionPanel(
    'Outfit colour',
    'Choose the colour your avatar wears.',
    Wrap(
      spacing: 13,
      runSpacing: 14,
      children: [for (var i = 0; i < avatarKeys.length; i++) _themeChoice(i)],
    ),
  );

  Widget _themeChoice(int index) {
    final selected = avatarKey == avatarKeys[index];
    return Semantics(
      label: '${avatarKeys[index]} outfit colour',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () => setState(() => avatarKey = avatarKeys[index]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColors[index],
                border: Border.all(
                  color: selected ? sage : Colors.white,
                  width: selected ? 3 : 2,
                ),
                boxShadow: selected
                    ? const [BoxShadow(color: Color(0x22000000), blurRadius: 5)]
                    : null,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(height: 5),
            Text(
              avatarKeys[index][0].toUpperCase() +
                  avatarKeys[index].substring(1),
              style: TextStyle(
                color: selected ? sage : muted,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionPanel(String title, String subtitle, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: GoogleFonts.dmSans(color: muted, fontSize: 12)),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _choiceRow(
    List<String> labels,
    int selected,
    ValueChanged<int> onSelect,
  ) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      for (var i = 0; i < labels.length; i++)
        ChoiceChip(
          label: Text(labels[i]),
          selected: selected == i,
          onSelected: (_) => onSelect(i),
          showCheckmark: false,
          labelStyle: TextStyle(
            fontSize: 11,
            color: selected == i ? sage : ink,
            fontWeight: FontWeight.w700,
          ),
          selectedColor: const Color(0xFFEAF0E4),
          backgroundColor: cream,
          side: BorderSide(color: selected == i ? sage : line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3),
        ),
    ],
  );

  Widget _selectCard(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF0E4) : cream,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? sage : line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? sage : muted, size: 23),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: selected ? sage : ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _toneChoice(
    Color color,
    bool selected,
    String label,
    VoidCallback onTap, {
    double size = 39,
  }) => Semantics(
    label: label,
    selected: selected,
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? sage : Colors.white,
            width: selected ? 3 : 2,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x22000000), blurRadius: 4)]
              : null,
        ),
        child: selected
            ? Icon(Icons.check_rounded, color: Colors.white, size: size * .45)
            : null,
      ),
    ),
  );

  Widget _miniLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: muted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}
