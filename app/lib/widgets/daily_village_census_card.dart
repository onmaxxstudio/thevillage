import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/village_census_service.dart';

class DailyVillageCensusCard extends StatefulWidget {
  const DailyVillageCensusCard({super.key});
  @override
  State<DailyVillageCensusCard> createState() => _DailyVillageCensusCardState();
}

class _DailyVillageCensusCardState extends State<DailyVillageCensusCard> {
  final service = VillageCensusService();
  bool submitting = false;
  bool allowAggregateUse = false;
  String? error;

  String get dayKey {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.questionForDate(dayKey).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.data()?['status'] != 'published') return const SizedBox.shrink();
        final doc = snapshot.data!;
        final data = doc.data()!;
        final options = List<String>.from(data['options'] ?? []);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E2DD),
            border: Border.all(color: const Color(0xFFE3D8C9)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TODAY’S VILLAGE QUESTION',
                style: GoogleFonts.inter(color: const Color(0xFF355C3B),
                    fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            Text((data['text'] ?? '').toString(),
                style: GoogleFonts.playfairDisplay(fontSize: 22,
                    fontWeight: FontWeight.w600, color: const Color(0xFF172019))),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: service.watchMyVote(doc.id),
              builder: (context, voteSnapshot) {
                if (!voteSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (voteSnapshot.data!.exists) {
                  return Text('Your vote: ${voteSnapshot.data!.data()?['option']}. Thanks for sharing your voice!',
                      style: const TextStyle(color: Color(0xFF355C3B), fontWeight: FontWeight.w600));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: allowAggregateUse,
                      onChanged: submitting
                          ? null
                          : (value) => setState(() => allowAggregateUse = value ?? false),
                      title: const Text(
                        'I agree my answer may be included in grouped reports sold or shared with research or marketing partners. They receive totals only, not my account or individual vote.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF355C3B)),
                      ),
                    ),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final option in options)
                        OutlinedButton(
                          onPressed: submitting ? null : () async {
                            setState(() { submitting = true; error = null; });
                            try {
                              await service.vote(
                                questionId: doc.id,
                                option: option,
                                allowAggregateUse: allowAggregateUse,
                              );
                            } catch (e) {
                              if (mounted) setState(() => error = 'Could not save your vote. Please try again.');
                            } finally {
                              if (mounted) setState(() => submitting = false);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFAF1),
                            foregroundColor: const Color(0xFF355C3B),
                            side: const BorderSide(color: Color(0xFF355C3B)),
                          ),
                          child: Text(option.toUpperCase()),
                        ),
                    ]),
                  ],
                );
              },
            ),
            if (error != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 6),
            const Text('One vote per member. Report summaries include only answers with opt-in and are hidden until at least 20 members opt in.',
                style: TextStyle(fontSize: 11, color: Color(0xFF355C3B))),
          ]),
        );
      },
    );
  }
}
