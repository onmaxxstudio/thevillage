import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'village_plus_screen.dart';
import '../widgets/monthly_focus_screen.dart';

/// Public event metadata lives in admin_events; links and recordings are in
/// admin_events/{id}/private/details and protected by Firebase rules.
class MonthlyGatheringScreen extends StatefulWidget {
  const MonthlyGatheringScreen({super.key, this.eventId});
  final String? eventId;
  @override
  State<MonthlyGatheringScreen> createState() => _MonthlyGatheringScreenState();
}

class _MonthlyGatheringScreenState extends State<MonthlyGatheringScreen> {
  static const green = Color(0xFF003B23), cream = Color(0xFFFFFAF1), gold = Color(0xFFB78943);
  Timer? clock;
  DateTime now = DateTime.now();
  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(seconds: 30), (_) { if (mounted) setState(() => now = DateTime.now()); });
  }
  @override
  void dispose() { clock?.cancel(); super.dispose(); }

  Future<bool> _eligible() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('village_plus_memberships').doc(uid).get();
    final data = doc.data();
    final end = data?['currentPeriodEnd'];
    return data?['villagePlus'] == true &&
        (data?['status'] == 'active' || data?['status'] == 'trialing') &&
        end is Timestamp && end.toDate().isAfter(DateTime.now());
  }

  Future<void> _reserve(String id, bool registered) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { _message('Sign in to reserve a spot.'); return; }
    try {
      final ref = FirebaseFirestore.instance.collection('admin_events').doc(id).collection('registrations').doc(uid);
      if (registered) { await ref.delete(); } else {
        await ref.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
      }
      _message(registered ? 'Reservation canceled.' : 'Your spot is reserved.');
    } catch (_) { _message('Could not update your reservation. Please try again.'); }
  }
  void _message(String value) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }
  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || !await launchUrl(uri, mode: LaunchMode.externalApplication)) _message('This link is unavailable.');
  }
  Future<void> _join(String eventId, String url) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('admin_events').doc(eventId)
          .collection('registrations').doc(uid).update({'joinedAt': FieldValue.serverTimestamp()});
      await _open(url);
    } catch (_) { _message('The event could not be joined. Check your membership and try again.'); }
  }
  Future<void> _recording(String eventId) async {
    try {
      final response = await FirebaseFunctions.instanceFor(region: 'us-east1')
          .httpsCallable('getGatheringRecording').call<Map<String, dynamic>>({'eventId':eventId});
      final url = response.data['url']?.toString() ?? '';
      if (url.isEmpty) throw StateError('Missing recording');
      await _open(url);
    } catch (_) { _message('Recording is unavailable or your access has ended.'); }
  }

  @override
  Widget build(BuildContext context) => Firebase.apps.isEmpty
      ? Scaffold(appBar: AppBar(title: const Text('The Monthly Gathering')), body: const Center(child: Text('The next Monthly Gathering has not been announced.')))
      : Scaffold(
    backgroundColor: cream,
    appBar: AppBar(title: const Text('The Monthly Gathering'), backgroundColor: cream, foregroundColor: green),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.eventId == null
          ? FirebaseFirestore.instance.collection('admin_events').where('published', isEqualTo: true).snapshots()
          : null,
      builder: (context, list) {
        if (widget.eventId == null && list.hasError) return const Center(child: Text('Events are unavailable.'));
        final docs = list.data?.docs.where((d) => d.data()['kind'] == 'monthly_gathering').toList() ?? [];
        final id = widget.eventId ?? (docs.isEmpty ? null : docs.first.id);
        if (id == null) return const Center(child: Text('The next Monthly Gathering has not been announced.'));
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('admin_events').doc(id).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('This event is unavailable.'));
            final data = snapshot.data?.data();
            if (data == null || data['published'] != true) return const Center(child: Text('The next Monthly Gathering has not been announced.'));
            final start = data['startsAt'] is Timestamp ? (data['startsAt'] as Timestamp).toDate() : null;
            final duration = data['durationMinutes'] is int ? data['durationMinutes'] as int : 60;
            final plus = data['access'] == 'plus';
            final uid = FirebaseAuth.instance.currentUser?.uid;
            final reservation = uid == null ? null : FirebaseFirestore.instance.collection('admin_events').doc(id).collection('registrations').doc(uid);
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: reservation?.snapshots(),
              builder: (context, registration) => FutureBuilder<bool>(
                future: plus ? _eligible() : Future.value(true),
                builder: (context, entitlement) {
                  final eligible = entitlement.data == true;
                  final registered = registration.data?.exists == true;
                  final live = start != null && now.isAfter(start) && now.isBefore(start.add(Duration(minutes: duration)));
                  return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: ListView(
                    padding: const EdgeInsets.all(20), children: [
                      if ((data['imageUrl'] ?? '').toString().isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(data['imageUrl'].toString(), height: 220, fit: BoxFit.cover)),
                      const SizedBox(height: 16),
                      Text(plus ? 'VILLAGE PLUS EXCLUSIVE' : 'FREE VILLAGE EVENT', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
                      const SizedBox(height: 10), Text('The Monthly Gathering', style: TextStyle(color: green, fontSize: 28, fontFamily: 'VillagePlusDisplay')),
                      const Text('Connect. Learn. Grow together.', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16), Text(data['title']?.toString() ?? '', style: const TextStyle(fontSize: 24, color: green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 9), Text(data['description']?.toString() ?? ''),
                      const SizedBox(height: 18), Text(start == null ? 'Date and time to be announced' : '${MaterialLocalizations.of(context).formatFullDate(start.toLocal())} • ${TimeOfDay.fromDateTime(start.toLocal()).format(context)} • $duration minutes'),
                      if (start != null && start.isAfter(now)) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Starts in ${start.difference(now).inDays} days, ${start.difference(now).inHours.remainder(24)} hours', style: const TextStyle(color: gold))),
                      if (data['status'] == 'canceled') const Text('This gathering has been canceled.'),
                      if (plus && !eligible) FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const VillagePlusScreen())), child: const Text('Explore Village Plus')),
                      if (eligible && uid != null && start != null && start.isAfter(now) && data['status'] != 'canceled') FilledButton(onPressed: () => _reserve(id, registered), child: Text(registered ? 'Cancel Reservation' : 'Reserve My Spot')),
                      if (registered) const Text('Your reservation is confirmed. Check this page when the event begins.'),
                      if (registered && start != null) TextButton(onPressed: () {
                        final end = start.add(Duration(minutes: duration));
                        String stamp(DateTime value) => value.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first + 'Z';
                        _open('https://calendar.google.com/calendar/render?action=TEMPLATE&text=${Uri.encodeComponent(data['title']?.toString() ?? 'The Monthly Gathering')}&dates=${stamp(start)}/${stamp(end)}');
                      }, child: const Text('Add to Calendar')),
                      if (registered && live && eligible) FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(future: FirebaseFirestore.instance.collection('admin_events').doc(id).collection('private').doc('details').get(), builder: (context, private) {
                        final link = private.data?.data()?['meetingUrl']?.toString() ?? '';
                        return link.isEmpty ? const SizedBox.shrink() : FilledButton(onPressed: () => _join(id, link), child: const Text('Join Live Event'));
                      }),
                      const SizedBox(height: 22), const Text('What to Expect', style: TextStyle(fontSize: 20, color: green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8), Text(data['whatToExpect']?.toString() ?? 'A guided conversation, reflection, and practical takeaways.'),
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MonthlyFocusScreen())), child: const Text('Explore Monthly Focus')),
                      const SizedBox(height: 18), const Text('Previous Gatherings', style: TextStyle(fontSize: 20, color: green, fontWeight: FontWeight.bold)),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection('admin_events').where('published', isEqualTo: true).snapshots(),
                        builder: (context, history) {
                          final previous = history.data?.docs.where((doc) {
                            final item = doc.data();
                            final date = item['startsAt'];
                            return item['kind'] == 'monthly_gathering' && doc.id != id &&
                                date is Timestamp && date.toDate().isBefore(now);
                          }).toList() ?? [];
                          previous.sort((a, b) => (b.data()['startsAt'] as Timestamp).compareTo(a.data()['startsAt'] as Timestamp));
                          return Column(children: [for (final past in previous)
                            ListTile(title: Text(past.data()['title']?.toString() ?? 'Gathering'),
                              subtitle: Text(MaterialLocalizations.of(context).formatFullDate((past.data()['startsAt'] as Timestamp).toDate().toLocal())),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => MonthlyGatheringScreen(eventId: past.id))))]);
                        }),
                      if (registered && eligible && data['recordingAvailable'] == true)
                        TextButton(onPressed: () => _recording(id), child: const Text('Get recording')),
                      if (data['recordingAvailable'] != true) const Text('Recordings will appear here when available.'),
                    ],
                  )));
                },
              ),
            );
          },
        );
      },
    ),
  );
}
