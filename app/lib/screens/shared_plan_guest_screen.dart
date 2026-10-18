import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Read-only, no-account view for a private weekly-plan link.
class SharedPlanGuestScreen extends StatelessWidget {
  const SharedPlanGuestScreen({super.key, required this.token});

  final String token;
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE6DFD2);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(backgroundColor: cream, foregroundColor: ink, elevation: 0,
      title: Text('Shared Planning', style: GoogleFonts.playfairDisplay(
        color: ink, fontWeight: FontWeight.w600))),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('weekly_plan_shares')
          .doc(token).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: sage));
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return _message('This sharing link is unavailable',
              'The owner may have revoked access, or the link may have expired.');
          }
          final data = snapshot.data!.data() ?? {};
          final expiresAt = data['expiresAt'];
          if (expiresAt is Timestamp && expiresAt.toDate().isBefore(DateTime.now())) {
            return _message('This sharing link has expired',
              'Ask the person who shared it to create a new link.');
          }
          final payload = Map<String, dynamic>.from(data['payload'] as Map? ?? {});
          final weekLabel = data['weekLabel'] as String? ?? 'Weekly plan';
          return ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [
            _card(Row(children: [
              const CircleAvatar(backgroundColor: Color(0xFFE8EBDD),
                child: Icon(Icons.visibility_outlined, color: sage)),
              const SizedBox(width: 12),
              const Expanded(child: Text('View only · Shared with you',
                style: TextStyle(fontWeight: FontWeight.w600))),
            ])),
            const SizedBox(height: 16),
            Text(weekLabel, style: GoogleFonts.playfairDisplay(fontSize: 23,
              color: ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (payload['tasks'] is List)
              _itemsCard('Tasks', Icons.checklist, (payload['tasks'] as List)
                .whereType<Map>().map((item) => Map<String, dynamic>.from(item))
                .map((item) => '${item['done'] == true ? '✓' : '○'}  ${item['title'] ?? ''}'
                  '${item['day'] is String ? ' · ${item['day']}' : ''}').toList()),
            if (payload['meals'] is Map)
              _itemsCard('Meals', Icons.restaurant_outlined,
                _datedEntries(Map<String, dynamic>.from(payload['meals'] as Map))),
            if (payload['groceries'] is List)
              _itemsCard('Grocery list', Icons.shopping_basket_outlined,
                (payload['groceries'] as List).whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .map((item) => '${item['done'] == true ? '✓' : '○'}  ${item['title'] ?? ''}').toList()),
            if (payload['notes'] is Map)
              _itemsCard('Weekly schedule', Icons.calendar_month_outlined,
                _datedEntries(Map<String, dynamic>.from(payload['notes'] as Map))),
            const SizedBox(height: 12),
            const Text('This link gives view-only access to the sections the owner selected.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ]);
        },
      ),
    )),
  );

  List<String> _datedEntries(Map<String, dynamic> entries) => entries.entries
    .where((entry) => entry.value is String && (entry.value as String).trim().isNotEmpty)
    .map((entry) => entry.key == 'week'
      ? 'This week · ${entry.value}' : '${entry.key} · ${entry.value}').toList();

  Widget _message(String title, String detail) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: _card(Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.link_off_outlined, color: sage, size: 30),
        const SizedBox(height: 10),
        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 21,
          color: ink, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6), Text(detail),
      ])),
  ));

  Widget _itemsCard(String title, IconData icon, List<String> entries) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: sage), const SizedBox(width: 9),
        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 19,
          color: ink, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 8),
      if (entries.isEmpty) const Text('Nothing added for this week.',
        style: TextStyle(color: Colors.black54)),
      for (final entry in entries) Padding(
        padding: const EdgeInsets.symmetric(vertical: 4), child: Text(entry)),
    ])),
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
      border: Border.all(color: line), borderRadius: BorderRadius.circular(18)),
    child: child,
  );
}
