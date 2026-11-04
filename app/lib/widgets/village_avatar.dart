import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'village_portrait.dart';

class VillageAvatar extends StatelessWidget {
  const VillageAvatar({super.key, this.uid, this.radius = 20, this.anonymous = false, this.photoUrl, this.avatarMode, this.avatarKey, this.avatarSkin, this.avatarHair, this.avatarHairColor, this.avatarFace, this.avatarEyes, this.avatarSmile, this.avatarPresentation, this.avatarFacialHair, this.avatarMole, this.avatarNose, this.avatarBrows, this.avatarGlasses, this.avatarFreckles, this.avatarEyeColor});
  final String? uid;
  final double radius;
  final bool anonymous;
  final String? photoUrl;
  final String? avatarMode;
  final String? avatarKey;
  final int? avatarSkin;
  final int? avatarHair;
  final int? avatarHairColor;
  final int? avatarFace;
  final int? avatarEyes;
  final int? avatarSmile;
  final int? avatarPresentation;
  final int? avatarFacialHair;
  final int? avatarMole;
  final int? avatarNose;
  final int? avatarBrows;
  final int? avatarGlasses;
  final int? avatarFreckles;
  final int? avatarEyeColor;

  static const _avatarKeys = <String>[
    'sage', 'rose', 'gold', 'sky', 'lavender', 'peach',
    'cobalt', 'plum', 'coral', 'mint', 'teal', 'amber',
  ];
  static final Map<String, Future<Map<String, dynamic>?>> _profileCache = {};
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static void invalidate(String uid) { _profileCache.remove(uid); revision.value++; }

  Future<Map<String, dynamic>?> _load() {
    final profileUid = uid;
    if (profileUid == null || profileUid.isEmpty || Firebase.apps.isEmpty) {
      return Future.value(null);
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (profileUid == currentUid && avatarMode != null) {
      return Future.value({
        'avatarMode': avatarMode,
        'avatarKey': avatarKey,
        'photoUrl': photoUrl,
        'avatarSkin': avatarSkin,
        'avatarHair': avatarHair,
        'avatarHairColor': avatarHairColor,
        'avatarFace': avatarFace,
        'avatarEyes': avatarEyes,
        'avatarSmile': avatarSmile,
        'avatarPresentation': avatarPresentation,
        'avatarFacialHair': avatarFacialHair,
        'avatarMole': avatarMole,
        'avatarNose': avatarNose,
        'avatarBrows': avatarBrows,
        'avatarGlasses': avatarGlasses,
        'avatarFreckles': avatarFreckles,
        'avatarEyeColor': avatarEyeColor,
      });
    }
    return _profileCache.putIfAbsent(profileUid, () async {
      try {
        return (await FirebaseFirestore.instance
                .collection('public_profiles')
                .doc(profileUid)
                .get())
            .data();
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (anonymous) return CircleAvatar(radius: radius, backgroundColor: const Color(0xFFF3E2DD), child: Icon(Icons.visibility_off_outlined, color: const Color(0xFF355C3B), size: radius));
    return ValueListenableBuilder<int>(
      valueListenable: revision,
      builder: (context, _, __) => FutureBuilder<Map<String, dynamic>?>(
        future: _load(),
        builder: (context, snapshot) => _fromData(snapshot.data),
      ),
    );
  }

  Widget _fromData(Map<String, dynamic>? data) {
    // Legacy private/photo records fall back to the default illustrated avatar.
    final mode = data?['avatarMode'] as String? ?? avatarMode ?? 'avatar';
    final key = data?['avatarKey'] as String? ?? avatarKey ?? 'sage';
    final index = mode == 'avatar' ? _avatarKeys.indexOf(key) : -1;
    int? appearance(String field) {
      final value = data?[field] ?? switch (field) {
        'avatarSkin' => avatarSkin,
        'avatarHair' => avatarHair,
        'avatarHairColor' => avatarHairColor,
        'avatarFace' => avatarFace,
        'avatarEyes' => avatarEyes,
        'avatarSmile' => avatarSmile,
        'avatarPresentation' => avatarPresentation,
        'avatarFacialHair' => avatarFacialHair,
        'avatarMole' => avatarMole,
        'avatarNose' => avatarNose,
        'avatarBrows' => avatarBrows,
        'avatarGlasses' => avatarGlasses,
        'avatarFreckles' => avatarFreckles,
        'avatarEyeColor' => avatarEyeColor,
        _ => null,
      };
      return value is num ? value.toInt() : null;
    }
    return ClipOval(child: SizedBox.square(dimension: radius * 2, child: VillagePortrait(
      outfit: index < 0 ? 0 : index,
      skin: appearance('avatarSkin') ?? 5,
      hair: appearance('avatarHair') ?? 0,
      hairColor: appearance('avatarHairColor') ?? 0,
      face: appearance('avatarFace') ?? 0,
      eyes: appearance('avatarEyes') ?? 0,
      smile: appearance('avatarSmile') ?? 0,
      presentation: appearance('avatarPresentation') ?? 2,
      facialHair: appearance('avatarFacialHair') ?? 0,
      mole: appearance('avatarMole') ?? 0,
      nose: appearance('avatarNose') ?? 0,
      brows: appearance('avatarBrows') ?? 0,
      glasses: appearance('avatarGlasses') ?? 0,
      freckles: appearance('avatarFreckles') ?? 0,
      eyeColor: appearance('avatarEyeColor') ?? 0,
    )));
  }

}
