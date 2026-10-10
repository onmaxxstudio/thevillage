import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Guided intake only: no eligibility determination or invented matching scores.
class GuidedHelpAssistant extends StatefulWidget {
  const GuidedHelpAssistant({super.key, required this.onBrowse});
  final void Function(String need, String? state, String? zip) onBrowse;

  @override
  State<GuidedHelpAssistant> createState() => _GuidedHelpAssistantState();
}

class _GuidedHelpAssistantState extends State<GuidedHelpAssistant> {
  static const green = Color(0xFF25694A);
  static const ink = Color(0xFF1B2921);
  int step = 0;
  String need = 'Rent & Housing';
  String? state;
  String household = 'Prefer not to say';
  String urgency = 'As soon as possible';
  final zip = TextEditingController();
  static const options = <(String, String, IconData)>[
    ('Rent & Housing', 'I need help with rent', Icons.home_outlined),
    ('Food', 'I need food', Icons.restaurant_outlined),
    ('Employment', 'I lost my job', Icons.work_outline),
    ('Healthcare', 'I need healthcare', Icons.favorite_outline),
    ('Childcare', 'Help for my child', Icons.child_care_outlined),
    ('Crisis & Safety', 'I need urgent support', Icons.health_and_safety_outlined),
  ];
  static const states = <String>[
    'Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut',
    'Delaware','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa',
    'Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan',
    'Minnesota','Mississippi','Missouri','Montana','Nebraska','Nevada',
    'New Hampshire','New Jersey','New Mexico','New York','North Carolina',
    'North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island',
    'South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont',
    'Virginia','Washington','West Virginia','Wisconsin','Wyoming',
  ];

  @override
  void dispose() { zip.dispose(); super.dispose(); }

  Widget choice(String title, bool active, VoidCallback onTap, {IconData? icon}) =>
    Padding(padding: const EdgeInsets.only(bottom: 9), child: Material(
      color: active ? const Color(0xFFE6F1E8) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: active ? green : const Color(0xFFE8DED6)),
            borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, color: green), const SizedBox(width: 12)],
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            if (active) const Icon(Icons.check_circle, color: green),
          ]),
        ),
      ),
    ));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE9DE), Color(0xFFFFFAF5)])),
      child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            TextButton.icon(onPressed: () => setState(() => step = step == 0 ? 0 : step - 1),
              icon: const Icon(Icons.chevron_left), label: Text(step == 0 ? 'Find help' : 'Back')),
            const Spacer(),
            Text('Step ${step + 1} of 3', style: const TextStyle(color: green)),
          ]),
          LinearProgressIndicator(value: (step + 1) / 3, color: green,
            backgroundColor: const Color(0xFFF5D8C9)),
          const SizedBox(height: 22),
          Text(step == 0 ? "Let's find the right help" :
               step == 1 ? 'Where do you need help?' : 'Tell us a little more',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(fontSize: 25, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 7),
          Text(step == 0 ? 'Choose the situation that fits best.' :
               step == 1 ? 'Location helps narrow down available programs.' :
               'These details are optional. We do not determine eligibility.',
            textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF665D57))),
          const SizedBox(height: 24),
          if (step == 0) ...[
            for (final option in options)
              choice(option.$2, need == option.$1,
                () => setState(() => need = option.$1), icon: option.$3),
          ] else if (step == 1) ...[
            const Text('State', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: state, isExpanded: true,
              decoration: const InputDecoration(filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(), hintText: 'Choose a state'),
              items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => state = v),
            ),
            const SizedBox(height: 18),
            TextField(controller: zip, keyboardType: TextInputType.number,
              maxLength: 5,
              decoration: const InputDecoration(labelText: 'ZIP code (optional)',
                filled: true, fillColor: Colors.white, border: OutlineInputBorder())),
            const Text('You can continue without sharing a precise location.',
              style: TextStyle(fontSize: 12, color: Color(0xFF665D57))),
          ] else ...[
            const Text('Household (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (final h in ['Prefer not to say','Single adult','Parent with children','Couple','Other'])
              choice(h, household == h, () => setState(() => household = h)),
            const SizedBox(height: 10),
            const Text('How soon do you need help?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: urgency,
              decoration: const InputDecoration(filled: true, fillColor: Colors.white,
                border: OutlineInputBorder()),
              items: ['As soon as possible','This week','Planning ahead']
                .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) { if (v != null) setState(() => urgency = v); },
            ),
            const SizedBox(height: 12),
            const Text('Your answers stay in this screen; we only use your selected need and location to browse existing listings.',
              style: TextStyle(fontSize: 12, color: Color(0xFF665D57))),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (step < 2) { setState(() => step++); return; }
              widget.onBrowse(need, state, zip.text.trim().length == 5 ? zip.text.trim() : null);
            },
            style: FilledButton.styleFrom(backgroundColor: green,
              padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(step == 2 ? 'Find My Help Plan' : 'Next'),
          ),
        ],
      )),
    );
  }
}
