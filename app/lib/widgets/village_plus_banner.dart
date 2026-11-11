import 'package:flutter/material.dart';
import '../screens/village_plus_screen.dart';

class VillagePlusBanner extends StatelessWidget {
  const VillagePlusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF073C24);
    const gold = Color(0xFFF5CB62);
    return Material(
      color: forest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: const Color(0x400D3020),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const VillagePlusScreen(),
        )),
        child: Stack(
          children: [
            const Positioned(left: -22, bottom: -28,
              child: IgnorePointer(child: Icon(Icons.spa_rounded,
                size: 110, color: Color(0xFF466B3C)))),
            const Positioned(left: 33, bottom: -12,
              child: IgnorePointer(child: Icon(Icons.eco_rounded,
                size: 49, color: Color(0xFFB99B4E)))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 360 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final description = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: gold,
                        borderRadius: BorderRadius.circular(12)),
                      child: const Text('NEW', style: TextStyle(color: forest,
                        fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 6),
                    Text('Village Plus', style: TextStyle(fontFamily: 'VillagePlusDisplay',
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: compact ? 27 : 32)),
                    const SizedBox(height: 7),
                    const Text('Deeper support. Exclusive tools.\nMonthly workshop. And more.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45)),
                  ],
                );
                final price = Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('\$4.99', style: TextStyle(color: gold,
                    fontSize: 27, fontWeight: FontWeight.w800)),
                  const Text('/month', style: TextStyle(color: Colors.white, fontSize: 12)),
                ]);
                const arrow = CircleAvatar(radius: 20, backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_forward_rounded, color: forest, size: 23));
                if (compact) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    description,
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: gold, height: 1)),
                    Row(children: [Expanded(child: price), const SizedBox(width: 12), arrow]),
                  ]);
                }
                return Row(children: [
                  Expanded(child: description),
                  Container(margin: const EdgeInsets.symmetric(horizontal: 18),
                    width: 1, height: 72, color: gold),
                  price,
                  const SizedBox(width: 16),
                  arrow,
                ]);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
