import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VillagePlusScreen extends StatelessWidget {
  const VillagePlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF073C24);
    const gold = Color(0xFFEBC35D);
    const cream = Color(0xFFFFFAF1);
    const benefits = [
      (Icons.menu_book_outlined, 'My Growth Studio', 'Guided journaling and personal growth journeys'),
      (Icons.groups_outlined, 'Village Sessions', 'Monthly live group workshops'),
      (Icons.spa_outlined, 'The Monthly Reset', 'Fresh reflection challenges and workbooks'),
      (Icons.insights_outlined, 'Personal Insights', 'Explore your progress over time'),
    ];
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Village Plus'), backgroundColor: cream),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: green, borderRadius: BorderRadius.circular(24),
                ),
                child: Column(children: [
                  const Icon(Icons.eco_outlined, color: gold, size: 34),
                  const SizedBox(height: 12),
                  Text('Village Plus', style: GoogleFonts.playfairDisplay(
                    fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  const Text('Grow into the life you’re creating.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 12),
                  const Text('A little more support for every season of life.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFE6E9DF))),
                ]),
              ),
              const SizedBox(height: 22),
              for (final benefit in benefits)
                Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(benefit.$1, color: green),
                    title: Text(benefit.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(benefit.$3),
                  ),
                ),
              const SizedBox(height: 20),
              const Center(child: Text('\$4.99 / month',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: green))),
              const SizedBox(height: 12),
              const Text('Membership enrollment is coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: green)),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
