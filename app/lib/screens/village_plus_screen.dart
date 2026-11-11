import 'package:flutter/material.dart';

class VillagePlusScreen extends StatelessWidget {
  const VillagePlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF073C24);
    const gold = Color(0xFFEBC35D);
    const cream = Color(0xFFFFFAF1);
    const experiences = [
      (Icons.menu_book_outlined, 'My Growth Studio', [
        'Premium guided journaling',
        'Personal growth journeys',
        'Advanced reflection and progress insights',
      ]),
      (Icons.groups_outlined, 'The Village Sessions', [
        'Monthly live group workshops',
        'Guided conversations and practical takeaways',
      ]),
      (Icons.spa_outlined, 'The Monthly Reset', [
        'Monthly personal growth themes',
        'Guided challenges',
        'Downloadable reflection workbooks',
      ]),
    ];
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Village Plus'), backgroundColor: cream),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(color: green,
                  borderRadius: BorderRadius.circular(24)),
                child: Column(children: [
                  const Icon(Icons.eco_outlined, color: gold, size: 34),
                  const SizedBox(height: 12),
                  Text('Village Plus', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'VillagePlusDisplay', fontSize: 36,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  const Text('Grow into the life you’re creating.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, height: 1.4)),
                  const SizedBox(height: 14),
                  const Text('More than an app. A space to reconnect with yourself, find encouragement, and grow at your own pace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFE6E9DF), fontSize: 15, height: 1.6)),
                ]),
              ),
              const SizedBox(height: 22),
              for (final experience in experiences)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7DECB))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(experience.$1, color: green, size: 30),
                      const SizedBox(height: 12),
                      Text(experience.$2, style: TextStyle(fontFamily: 'VillagePlusDisplay',
                        fontSize: 24, fontWeight: FontWeight.w600, color: green)),
                      const SizedBox(height: 10),
                      for (final benefit in experience.$3)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Padding(padding: EdgeInsets.only(top: 3),
                              child: Icon(Icons.check_rounded, size: 18, color: green)),
                            const SizedBox(width: 9),
                            Expanded(child: Text(benefit,
                              style: const TextStyle(fontSize: 15, height: 1.45))),
                          ]),
                        ),
                    ]),
                  ),
                ),
              const SizedBox(height: 10),
              const Center(child: Text('\$4.99/month',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: green))),
              const SizedBox(height: 18),
              // Enrollment stays disabled until server-verified subscriptions exist.
              FilledButton(
                key: const ValueKey('join-village-plus'),
                onPressed: null,
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: const Color(0xFFD9DCCF),
                  disabledForegroundColor: green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
                child: const Text('Join Village Plus'),
              ),
              const SizedBox(height: 12),
              const Text('Membership enrollment is coming soon. Payments are not yet available.',
                textAlign: TextAlign.center,
                style: TextStyle(color: green, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
