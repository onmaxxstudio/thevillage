import 'package:flutter/material.dart';

class VillagePlusPhoto extends StatelessWidget {
  const VillagePlusPhoto({super.key});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/village_plus_cozy.webp',
    fit: BoxFit.cover,
    alignment: Alignment.centerLeft,
    excludeFromSemantics: true,
  );
}
