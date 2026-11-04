import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared, resolution-independent portrait used in the builder and member circles.
/// Uses layered gradients rather than the legacy flat CustomPainter geometry.
class VillagePortrait extends StatelessWidget {
  const VillagePortrait({super.key, required this.skin, required this.hair,
    required this.hairColor, required this.face, required this.eyes,
    required this.smile, required this.presentation, required this.facialHair,
    required this.mole, required this.nose, required this.brows,
    required this.glasses, required this.freckles, required this.eyeColor,
    required this.outfit});
  final int skin, hair, hairColor, face, eyes, smile, presentation, facialHair,
      mole, nose, brows, glasses, freckles, eyeColor, outfit;

  static const skinTones = ['#3B2119','#563326','#704630','#81513D','#8B553A','#9C6045','#A66A4E','#B97855','#C98761','#D69A70','#E0AD86','#EDC29B'];
  static const hairTones = ['#171311','#2D211C','#542F23','#8A5837','#C17C36','#E1BE78','#4A4A47','#E1D9CC','#76509A','#B34E72'];
  static const shirts = ['#355C3B','#9E6257','#B5873F','#426A78','#72617E','#AD7654','#485D83','#855A74','#BD735D','#567663','#397778','#967241'];
  static const irises = ['#30231F','#79513B','#9A7A42','#52755B','#527B9B','#71818B'];

  String get svg {
    final s = skinTones[skin.clamp(0,11)];
    final h = hairTones[hairColor.clamp(0,9)];
    final shirt = shirts[outfit.clamp(0,11)];
    final iris = irises[eyeColor.clamp(0,5)];
    final masculine = presentation == 1;
    final width = face == 2 ? 66 : face == 1 ? 52 : masculine ? 62 : 57;
    final left = 100 - width / 2;
    final facePath = 'M ${left+7} 78 Q ${left+width/2} 54 ${left+width-7} 78 Q ${left+width+6} 117 ${left+width-12} 148 Q 100 166 ${left+12} 148 Q ${left-6} 117 ${left+7} 78 Z';
    final hairBack = hair == 10 ? '' : '<path d="M43 107 Q32 33 98 29 Q168 31 157 109 L151 169 Q139 180 135 162 L136 94 L65 94 L65 164 Q49 178 46 153Z" fill="url(#hair)" />';
    String curls = '';
    if (hair == 0 || hair == 4 || hair == 5) {
      final points = hair == 4 ? [[57,69,12],[78,45,12],[103,40,12],[126,45,12],[146,68,12]] :
        [[52,75,19],[59,52,20],[79,40,22],[103,34,22],[126,43,21],[146,58,20],[151,80,18]];
      curls = points.map((p) => '<circle cx="${p[0]}" cy="${p[1]}" r="${p[2]}" fill="url(#hair)"/>').join();
    } else if (hair == 1 || hair == 2 || hair == 3) {
      curls = List.generate(9,(i) {
        final x = 52+i*12;
        final thick = hair == 3 ? 5 : 8;
        return '<path d="M$x 55 Q${x-8} 96 ${x+((i%2)*6)} 170" stroke="url(#hair)" stroke-width="$thick" stroke-linecap="round" fill="none"/>';
      }).join();
    } else if (hair == 6 || hair == 7) {
      curls = '<path d="M67 82 Q73 48 105 51 Q136 51 137 82 Q102 68 67 82" fill="url(#hair)"/>';
    } else if (hair == 8) {
      curls = '<circle cx="100" cy="36" r="26" fill="url(#hair)"/>';
    } else if (hair == 9) {
      curls = '<ellipse cx="151" cy="104" rx="17" ry="49" fill="url(#hair)"/>';
    }
    final mouth = smile == 2 ? '<path d="M88 133 Q100 136 112 133" stroke="#814E4C" stroke-width="2.8" fill="none" stroke-linecap="round"/>' :
      '<path d="M86 131 Q100 ${smile==1?149:142} 114 131" stroke="#8E4D50" stroke-width="3.3" fill="none" stroke-linecap="round"/>';
    final beard = facialHair == 0 ? '' : facialHair == 1 ?
      '<path d="M77 136 Q100 165 123 136" stroke="$h" stroke-opacity=".4" stroke-width="5" stroke-dasharray="1 4" fill="none"/>' :
      '<path d="M86 129 Q93 124 100 130 Q107 124 114 129" stroke="$h" stroke-width="4.5" fill="none" stroke-linecap="round"/>${facialHair>=3?'<path d="M75 138 Q80 170 100 169 Q120 170 125 138 Q116 153 100 157 Q84 153 75 138" fill="$h" opacity=".9"/>':''}';
    final specs = glasses == 0 ? '' : '<g stroke="#453E39" stroke-width="2.6" fill="none"><rect x="67" y="100" width="28" height="22" rx="${glasses==1?5:12}"/><rect x="105" y="100" width="28" height="22" rx="${glasses==1?5:12}"/><path d="M95 110 Q100 106 105 110"/></g>';
    final dots = freckles == 0 ? '' : List.generate(8,(i) => '<circle cx="${72+(i%4)*7+(i>=4?37:0)}" cy="${124+(i%3)*3}" r="${freckles==1?1:1.7}" fill="#5C342B" opacity=".45"/>').join();
    final beauty = mole == 0 ? '' : '<circle cx="${mole==2?124:mole==3?101:76}" cy="${mole==3?146:132}" r="2.2" fill="#38231D"/>';
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
<defs>
<radialGradient id="bg" cx="35%" cy="22%" r="90%"><stop stop-color="#F7F4EB"/><stop offset="1" stop-color="#DCE7DB"/></radialGradient>
<radialGradient id="skin" cx="28%" cy="25%" r="85%"><stop stop-color="#FFFFFF" stop-opacity=".25"/><stop offset=".38" stop-color="$s"/><stop offset="1" stop-color="#170C08" stop-opacity=".36"/></radialGradient>
<linearGradient id="hair" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FFFFFF" stop-opacity=".2"/><stop offset=".35" stop-color="$h"/><stop offset="1" stop-color="#080606"/></linearGradient>
<linearGradient id="shirt" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FFFFFF" stop-opacity=".24"/><stop offset=".4" stop-color="$shirt"/><stop offset="1" stop-color="#17241C"/></linearGradient>
</defs>
<rect width="200" height="200" fill="url(#bg)"/>
<ellipse cx="100" cy="205" rx="95" ry="62" fill="url(#shirt)"/><path d="M55 198 Q67 166 84 169 Q100 186 116 169 Q139 168 145 198" fill="none" stroke="#FFFFFF" stroke-opacity=".12" stroke-width="7"/>
<path d="M84 139 L84 174 Q100 190 116 174 L116 139" fill="url(#skin)"/>
$hairBack
<ellipse cx="${left+2}" cy="116" rx="9" ry="15" fill="$s"/>
<ellipse cx="${left+width-2}" cy="116" rx="9" ry="15" fill="$s"/>
<path d="$facePath" fill="url(#skin)"/><path d="M${left+11} 116 Q${left+11} 151 100 155" fill="none" stroke="#FFFFFF" stroke-opacity=".09" stroke-width="4"/>
<circularGradient/>
<path d="M70 99 Q83 ${brows==1?91:94} 94 99 M106 99 Q117 ${brows==1?91:94} 130 99" stroke="$h" stroke-width="${brows==1?4:3}" stroke-linecap="round" fill="none"/>
<path d="M72 109 Q83 103 94 109" stroke="#31221D" stroke-opacity=".35" stroke-width="1.3" fill="none"/><ellipse cx="83" cy="111" rx="10" ry="${eyes==1?7:5.5}" fill="#FFF9F0"/>
<path d="M106 109 Q117 103 128 109" stroke="#31221D" stroke-opacity=".35" stroke-width="1.3" fill="none"/><ellipse cx="117" cy="111" rx="10" ry="${eyes==1?7:5.5}" fill="#FFF9F0"/>
<circle cx="84" cy="111" r="5" fill="$iris"/><circle cx="116" cy="111" r="5" fill="$iris"/>
<circle cx="85" cy="110" r="1.7" fill="white"/><circle cx="117" cy="110" r="1.7" fill="white"/>
<path d="M100 113 Q${nose==2?91:95} 127 101 128 Q105 129 109 126" stroke="#6B4137" stroke-opacity=".65" stroke-width="2.4" fill="none" stroke-linecap="round"/>
<ellipse cx="75" cy="126" rx="12" ry="6" fill="#DA827C" opacity=".16"/><ellipse cx="125" cy="126" rx="12" ry="6" fill="#DA827C" opacity=".16"/>
$mouth $dots $beauty $beard $specs
$curls
<path d="M63 79 Q68 49 100 50 Q134 48 139 80 Q113 68 100 72 Q82 69 63 79" fill="url(#hair)" opacity="${hair==10?0:1}"/><path d="M74 75 Q100 60 126 75" stroke="#FFFFFF" stroke-opacity=".09" stroke-width="2" fill="none"/>
</svg>'''.replaceAll('<circularGradient/>','');
  }

  @override
  Widget build(BuildContext context) => SvgPicture.string(svg, fit: BoxFit.cover);
}
