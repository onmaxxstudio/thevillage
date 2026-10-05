import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class VillageAvatar extends StatelessWidget {
  const VillageAvatar({super.key, this.uid, this.radius = 20, this.anonymous = false, this.photoUrl, this.avatarMode, this.avatarKey});
  final String? uid;
  final double radius;
  final bool anonymous;
  final String? photoUrl;
  final String? avatarMode;
  final String? avatarKey;

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
    return ClipOval(
      child: CustomPaint(
        size: Size.square(radius * 2),
        painter: _VillageAvatarPainter(index < 0 ? 0 : index),
      ),
    );
  }

}

class _VillageAvatarPainter extends CustomPainter {
  const _VillageAvatarPainter(this.index);
  final int index;

  static const _backgrounds = <Color>[
    Color(0xFFE8EBDD), Color(0xFFF3E2DD), Color(0xFFF4E8D2),
    Color(0xFFE1EBEE), Color(0xFFEAE5F0), Color(0xFFF4E3D4),
    Color(0xFFE3E9F3), Color(0xFFF0E1EA), Color(0xFFF7E5DE),
    Color(0xFFE2EEE7), Color(0xFFDDEBEA), Color(0xFFF3E9D7),
  ];
  static const _skin = <Color>[
    Color(0xFF6E3E2E), Color(0xFFC98761), Color(0xFF9C6045),
    Color(0xFFE0AD86), Color(0xFF81513D), Color(0xFFB97855),
    Color(0xFF563326), Color(0xFFD69A70), Color(0xFF704630),
    Color(0xFFEDC29B), Color(0xFFA66A4E), Color(0xFF8B553A),
  ];
  static const _hair = <Color>[
    Color(0xFF241915), Color(0xFF2D211C), Color(0xFF1D1715),
    Color(0xFF3A241B), Color(0xFF171514), Color(0xFF4A2D20),
    Color(0xFF171311), Color(0xFF30221C), Color(0xFF542F23),
    Color(0xFF29201C), Color(0xFF201917), Color(0xFF3C2921),
  ];
  static const _clothes = <Color>[
    Color(0xFF355C3B), Color(0xFF9E6257), Color(0xFFB5873F),
    Color(0xFF426A78), Color(0xFF72617E), Color(0xFFAD7654),
    Color(0xFF485D83), Color(0xFF855A74), Color(0xFFBD735D),
    Color(0xFF567663), Color(0xFF397778), Color(0xFF967241),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final i = index.clamp(0, 11).toInt();
    final ink = const Color(0xFF30231F);
    final hairColor = _hair[i];
    final skinColor = _skin[i];
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;

    fill.color = _backgrounds[i];
    canvas.drawRect(const Rect.fromLTWH(0, 0, 64, 64), fill);

    // Neck and shoulders
    fill.color = skinColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(27, 41, 10, 13), const Radius.circular(4)),
      fill,
    );
    fill.color = _clothes[i];
    final shoulders = Path()
      ..moveTo(8, 64)
      ..lineTo(10, 55)
      ..quadraticBezierTo(14, 48, 25, 47)
      ..lineTo(32, 52)
      ..lineTo(39, 47)
      ..quadraticBezierTo(51, 48, 54, 55)
      ..lineTo(56, 64)
      ..close();
    canvas.drawPath(shoulders, fill);

    // Hair silhouette behind the face; the styles vary across the set.
    fill.color = hairColor;
    canvas.drawOval(const Rect.fromLTWH(16, 8, 32, 43), fill);
    if (i == 0 || i == 6 || i == 9) {
      for (final point in const [Offset(20, 18), Offset(25, 12), Offset(32, 10), Offset(39, 12), Offset(44, 18), Offset(17, 25), Offset(47, 25)]) {
        canvas.drawCircle(point, 6, fill);
      }
    } else if (i == 3 || i == 11) {
      for (var x = 17.0; x <= 45; x += 7) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 22, 5, 29.0 + (x.toInt() % 3) * 2.0), const Radius.circular(3)), fill);
      }
    } else if (i == 5 || i == 8) {
      for (var x = 18.0; x <= 44; x += 6) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 24, 3.5, 31.0 + (x.toInt() % 2) * 3.0), const Radius.circular(2)), fill);
      }
    } else if (i == 7 || i == 10) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 18, 8, 35), const Radius.circular(6)), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 18, 8, 35), const Radius.circular(6)), fill);
    }

    // Head covering for one of the portraits, with a clear face opening.
    if (i == 2 || i == 8) {
      fill.color = i == 2 ? const Color(0xFF536E78) : const Color(0xFFAA755F);
      final scarf = Path()
        ..moveTo(12, 27)
        ..quadraticBezierTo(13, 6, 32, 5)
        ..quadraticBezierTo(52, 7, 52, 28)
        ..lineTo(49, 52)
        ..quadraticBezierTo(40, 48, 32, 48)
        ..quadraticBezierTo(23, 48, 15, 54)
        ..close();
      canvas.drawPath(scarf, fill);
    }

    // Ears and face
    fill.color = skinColor;
    canvas.drawOval(const Rect.fromLTWH(15, 27, 7, 12), fill);
    canvas.drawOval(const Rect.fromLTWH(42, 27, 7, 12), fill);
    canvas.drawOval(const Rect.fromLTWH(20, 17, 24, 34), fill);

    // Hairline and varied fringe
    fill.color = hairColor;
    if (i != 2 && i != 8) {
      canvas.drawOval(const Rect.fromLTWH(19, 13, 26, 15), fill);
      if (i == 1 || i == 4 || i == 7) {
        final fringe = Path()
          ..moveTo(20, 23)
          ..quadraticBezierTo(25, 13, 30, 21)
          ..quadraticBezierTo(35, 13, 43, 23)
          ..lineTo(42, 27)
          ..quadraticBezierTo(32, 21, 21, 28)
          ..close();
        canvas.drawPath(fringe, fill);
      }
    }

    if (i == 3 || i == 11) {
      fill.color = hairColor;
      final beard = Path()
        ..moveTo(21, 36)
        ..quadraticBezierTo(23, 45, 27, 47)
        ..quadraticBezierTo(32, 51, 37, 47)
        ..quadraticBezierTo(42, 44, 43, 36)
        ..quadraticBezierTo(39, 39, 36, 38)
        ..quadraticBezierTo(32, 41, 28, 38)
        ..close();
      canvas.drawPath(beard, fill);
    }

    // Brows, eyes, nose, and smile
    stroke.color = hairColor;
    canvas.drawLine(const Offset(24, 29), Offset(29, 29 + (i % 2 == 0 ? -1 : 0)), stroke);
    canvas.drawLine(const Offset(35, 29), Offset(40, 29 + (i % 3 == 0 ? -1 : 0)), stroke);
    fill.color = ink;
    canvas.drawOval(Rect.fromCenter(center: Offset(26.5, i % 3 == 0 ? 32 : 33), width: 2.1, height: i % 4 == 0 ? 1.4 : 2.1), fill);
    canvas.drawOval(Rect.fromCenter(center: Offset(37.5, i % 3 == 0 ? 32 : 33), width: 2.1, height: i % 4 == 0 ? 1.4 : 2.1), fill);
    stroke.color = Color.lerp(ink, skinColor, .22)!;
    stroke.strokeWidth = 1;
    canvas.drawLine(const Offset(32, 33), Offset(31 + (i % 3 - 1).toDouble(), 38), stroke);
    stroke.color = const Color(0xFF8B4C46);
    stroke.strokeWidth = 1.3;
    final smile = Path()
      ..moveTo(28, 42)
      ..quadraticBezierTo(32, 45 + (i % 2).toDouble(), 36, 42);
    canvas.drawPath(smile, stroke);

    if (i == 1 || i == 10) {
      fill.color = Color.lerp(ink, skinColor, .35)!;
      for (final point in const [Offset(23, 38), Offset(25, 39), Offset(39, 38), Offset(41, 39)]) {
        canvas.drawCircle(point, .65, fill);
      }
    }
    if (i == 0 || i == 4 || i == 9) {
      stroke.color = const Color(0xFF51413B);
      stroke.strokeWidth = 1.2;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(21, 29, 10, 8), const Radius.circular(3)), stroke);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(33, 29, 10, 8), const Radius.circular(3)), stroke);
      canvas.drawLine(const Offset(31, 32), const Offset(33, 32), stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VillageAvatarPainter oldDelegate) => oldDelegate.index != index;
}
