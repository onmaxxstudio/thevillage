import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/admin_content_service.dart';

class FindHelpScreen extends StatefulWidget {
  const FindHelpScreen({super.key});

  @override
  State<FindHelpScreen> createState() => _FindHelpScreenState();
}

class _FindHelpScreenState extends State<FindHelpScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final admin = AdminContentService();
  final zipController = TextEditingController();
  int view = 0;
  String? selectedState;
  String? selectedNeed;
  Set<String> saved = {};

  static const stateNames = <String, String>{
    'AL':'Alabama','AK':'Alaska','AZ':'Arizona','AR':'Arkansas','CA':'California',
    'CO':'Colorado','CT':'Connecticut','DE':'Delaware','FL':'Florida','GA':'Georgia',
    'HI':'Hawaii','ID':'Idaho','IL':'Illinois','IN':'Indiana','IA':'Iowa',
    'KS':'Kansas','KY':'Kentucky','LA':'Louisiana','ME':'Maine','MD':'Maryland',
    'MA':'Massachusetts','MI':'Michigan','MN':'Minnesota','MS':'Mississippi',
    'MO':'Missouri','MT':'Montana','NE':'Nebraska','NV':'Nevada','NH':'New Hampshire',
    'NJ':'New Jersey','NM':'New Mexico','NY':'New York','NC':'North Carolina',
    'ND':'North Dakota','OH':'Ohio','OK':'Oklahoma','OR':'Oregon','PA':'Pennsylvania',
    'RI':'Rhode Island','SC':'South Carolina','SD':'South Dakota','TN':'Tennessee',
    'TX':'Texas','UT':'Utah','VT':'Vermont','VA':'Virginia','WA':'Washington',
    'WV':'West Virginia','WI':'Wisconsin','WY':'Wyoming',
  };

  static const mapCells = <String>[
    'WA','','MT','ND','MN','WI','','MI','NY','ME',
    'OR','ID','WY','SD','IA','IL','IN','OH','PA','NH',
    'CA','NV','UT','CO','NE','MO','KY','WV','VA','MA',
    'AZ','NM','KS','OK','AR','TN','NC','SC','MD','CT',
    '','TX','LA','MS','AL','GA','FL','DE','NJ','RI',
    'AK','HI','','','','','','','','VT',
  ];

  static const needs = <(String, IconData)>[
    ('Food', Icons.restaurant_outlined),
    ('Rent & Housing', Icons.home_outlined),
    ('Utilities', Icons.lightbulb_outline_rounded),
    ('Healthcare', Icons.medical_services_outlined),
    ('Childcare', Icons.child_care_outlined),
    ('Transportation', Icons.directions_bus_outlined),
    ('Employment', Icons.work_outline_rounded),
    ('Legal Help', Icons.gavel_outlined),
    ('Crisis & Safety', Icons.health_and_safety_outlined),
  ];

  static const builtIns = <HelpResource>[
    HelpResource(
      id: '211',
      title: '211 Essential Community Services',
      description: 'Confidential help finding local food, housing, utility, healthcare, transportation, and other essential services.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Transportation','Employment','Legal Help','Crisis & Safety'],
      url: 'https://www.211.org/',
      phone: '211',
      label: 'Free • Nationwide',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'usa-benefits',
      title: 'USA.gov Benefit Finder',
      description: 'Answer a few questions to find government benefits and financial-help programs that may fit your situation.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Employment'],
      url: 'https://www.usa.gov/benefit-finder',
      label: 'Official government resource',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'food-help',
      title: 'Government Food Assistance',
      description: 'Learn about SNAP, WIC, emergency food programs, and other ways to get nutritious food.',
      needs: ['Food'],
      url: 'https://www.usa.gov/food-help',
      label: 'Official • Nationwide',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'rent-help',
      title: 'Emergency Rent Assistance',
      description: 'Find state and local options for emergency rental assistance and housing support.',
      needs: ['Rent & Housing'],
      url: 'https://www.usa.gov/emergency-pay-rent',
      label: 'Official • Nationwide',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'utility-help',
      title: 'Help With Utility Bills',
      description: 'Explore energy, phone, internet, heating, cooling, and weatherization assistance.',
      needs: ['Utilities'],
      url: 'https://www.usa.gov/help-with-utility-bills',
      label: 'Official • Nationwide',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'housing-help',
      title: 'USA.gov Housing Help',
      description: 'Find rental assistance, emergency housing, affordable housing, foreclosure, and home-repair information.',
      needs: ['Rent & Housing'],
      url: 'https://www.usa.gov/housing-help',
      label: 'Official • Nationwide',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'fl-benefits',
      title: 'Florida Public Assistance',
      description: 'Apply for Florida food assistance, temporary cash assistance, Medicaid, and refugee assistance.',
      needs: ['Food','Healthcare','Childcare','Rent & Housing'],
      states: ['FL'],
      url: 'https://www.myflfamilies.com/services/public-assistance',
      phone: '(850) 300-4323',
      label: 'Florida official resource',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'fl-homelessness',
      title: 'Florida Homelessness Assistance',
      description: 'Information about emergency shelter, housing stabilization, rental assistance, and local Continuums of Care.',
      needs: ['Rent & Housing','Crisis & Safety'],
      states: ['FL'],
      url: 'https://www.myflfamilies.com/services/abuse/homelessness',
      phone: '(850) 300-4323',
      label: 'Florida official resource',
      verified: 'September 2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    zipController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => saved = (preferences.getStringList('saved_help_resources') ?? const <String>[]).toSet());
    }
  }

  Future<void> _toggleSaved(String id) async {
    setState(() => saved.contains(id) ? saved.remove(id) : saved.add(id));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('saved_help_resources', saved.toList());
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That resource could not be opened.')));
    }
  }

  Future<void> _call(String phone) async {
    final value = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('tel:$value'));
  }

  List<HelpResource> _managed(List<ManagedContentItem> items) {
    return items
        .where((item) => item.data['helpResource'] == true)
        .map((item) => HelpResource(
              id: 'admin_${item.id}',
              title: item.text('title', 'Community resource'),
              description: item.text('description', item.text('body')),
              needs: item.text('need', item.text('category', 'General')).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
              states: item.text('state').split(',').map((e) => e.trim().toUpperCase()).where((e) => e.isNotEmpty).toList(),
              url: item.text('url'),
              phone: item.text('phone'),
              label: item.text('freeLabel', 'Community resource'),
              verified: item.text('verifiedAt', 'Check availability'),
            ))
        .toList();
  }

  List<HelpResource> _visible(List<HelpResource> managed) {
    var items = [...builtIns, ...managed];
    if (view == 2) {
      return items.where((resource) => saved.contains(resource.id)).toList();
    }
    if (selectedState != null) {
      items = items.where((resource) => resource.states.isEmpty || resource.states.contains(selectedState)).toList();
    }
    if (selectedNeed != null) {
      items = items.where((resource) => resource.needs.contains(selectedNeed)).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ManagedContentItem>>(
      stream: admin.cloudReady ? admin.watchPublished('resources') : Stream.value(const <ManagedContentItem>[]),
      builder: (context, snapshot) {
        final managed = _managed(snapshot.data ?? const <ManagedContentItem>[]);
        final visible = _visible(managed);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Text('Find Help', style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 4),
            Text('Free and low-cost support, organized by location and need.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF626A63))),
            const SizedBox(height: 14),
            _urgentBanner(),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Map'), icon: Icon(Icons.map_outlined)),
                ButtonSegment(value: 1, label: Text('By Need'), icon: Icon(Icons.grid_view_rounded)),
                ButtonSegment(value: 2, label: Text('Saved'), icon: Icon(Icons.bookmark_border_rounded)),
              ],
              selected: {view},
              onSelectionChanged: (value) => setState(() {
                view = value.first;
                if (view == 1) selectedState = null;
              }),
              style: ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 15),
            if (view == 0) _map(),
            if (view == 1) _needs(),
            if (view == 2) _savedHeader(),
            const SizedBox(height: 15),
            _zipSearch(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text(_resultsTitle(), style: GoogleFonts.playfairDisplay(fontSize: 23, fontWeight: FontWeight.w700, color: ink))),
                Text('${visible.length} resources', style: const TextStyle(color: sage, fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              _empty()
            else
              for (final resource in visible) ...[
                _resourceCard(resource),
                const SizedBox(height: 11),
              ],
            const SizedBox(height: 8),
            const Text(
              'Program availability and eligibility can change. Confirm details directly with the provider before relying on assistance.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: Color(0xFF737873), height: 1.4),
            ),
          ],
        );
      },
    );
  }

  Widget _urgentBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFF0D7), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE9C98C))),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFFFE2AF), child: Icon(Icons.support_agent_rounded, color: ink)),
          const SizedBox(width: 11),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Need help finding something now?', style: TextStyle(fontWeight: FontWeight.w900)),
            SizedBox(height: 2),
            Text('Call 211 for confidential local assistance.', style: TextStyle(fontSize: 12)),
          ])),
          TextButton(onPressed: () => _call('211'), child: const Text('Call')),
        ]),
      );

  Widget _map() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.touch_app_outlined, color: gold, size: 19),
            const SizedBox(width: 7),
            Expanded(child: Text(selectedState == null ? 'Tap a state to see available help' : stateNames[selectedState]!, style: const TextStyle(fontWeight: FontWeight.w800, color: ink))),
            if (selectedState != null) TextButton(onPressed: () => setState(() => selectedState = null), child: const Text('Clear')),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            final size = (constraints.maxWidth - 9 * 3) / 10;
            return Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final code in mapCells)
                  SizedBox(
                    width: size,
                    height: size * .82,
                    child: code.isEmpty
                        ? const SizedBox.shrink()
                        : InkWell(
                            onTap: () => setState(() => selectedState = code),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selectedState == code ? sage : paleSage,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: selectedState == code ? sage : const Color(0xFFC9D1C4)),
                              ),
                              child: FittedBox(child: Text(code, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: selectedState == code ? Colors.white : ink))),
                            ),
                          ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
          const Text('All 50 states are selectable. Nationwide resources appear for every state.', style: TextStyle(fontSize: 10.5, color: Color(0xFF6C726C))),
        ]),
      );

  Widget _needs() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final need in needs)
            FilterChip(
              avatar: Icon(need.$2, size: 17, color: selectedNeed == need.$1 ? Colors.white : sage),
              label: Text(need.$1),
              selected: selectedNeed == need.$1,
              onSelected: (_) => setState(() => selectedNeed = selectedNeed == need.$1 ? null : need.$1),
              selectedColor: sage,
              labelStyle: TextStyle(color: selectedNeed == need.$1 ? Colors.white : ink, fontWeight: FontWeight.w700),
            ),
        ],
      );

  Widget _savedHeader() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(18)),
        child: const Row(children: [
          Icon(Icons.bookmark_rounded, color: sage),
          SizedBox(width: 10),
          Expanded(child: Text('Resources you save will stay here for quick access.', style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _zipSearch() => TextField(
        controller: zipController,
        keyboardType: TextInputType.number,
        maxLength: 5,
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: const Icon(Icons.location_on_outlined, color: sage),
          hintText: 'Enter ZIP code for local help',
          suffixIcon: TextButton(
            onPressed: () {
              if (zipController.text.trim().length != 5) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a 5-digit ZIP code.')));
                return;
              }
              _open('https://www.211.org/');
            },
            child: const Text('Search'),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
        ),
      );

  String _resultsTitle() {
    if (view == 2) return 'Saved resources';
    if (selectedNeed != null) return selectedNeed!;
    if (selectedState != null) return 'Help in ${stateNames[selectedState]}';
    return 'Trusted nationwide help';
  }

  Widget _empty() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
        child: Column(children: [
          const Icon(Icons.search_off_rounded, color: sage, size: 32),
          const SizedBox(height: 7),
          Text(view == 2 ? 'No saved resources yet.' : 'No matching resources yet.', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Try another need or use 211 to find local help.', textAlign: TextAlign.center),
        ]),
      );

  Widget _resourceCard(HelpResource resource) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 43, height: 43, decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.volunteer_activism_outlined, color: sage)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(resource.title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 3),
              Text(resource.label, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900)),
            ])),
            IconButton(onPressed: () => _toggleSaved(resource.id), icon: Icon(saved.contains(resource.id) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: sage), tooltip: 'Save resource'),
          ]),
          const SizedBox(height: 9),
          Text(resource.description, style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: ink)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 5, children: [
            for (final need in resource.needs.take(3))
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(12)), child: Text(need, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 11),
          Row(children: [
            Expanded(child: Text('Verified: ${resource.verified}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF697069)))),
            if (resource.phone.isNotEmpty) TextButton.icon(onPressed: () => _call(resource.phone), icon: const Icon(Icons.call_outlined, size: 17), label: const Text('Call')),
            if (resource.url.isNotEmpty) FilledButton(onPressed: () => _open(resource.url), style: FilledButton.styleFrom(backgroundColor: sage, visualDensity: VisualDensity.compact), child: const Text('Visit')),
          ]),
        ]),
      );
}

class HelpResource {
  const HelpResource({
    required this.id,
    required this.title,
    required this.description,
    required this.needs,
    required this.url,
    required this.label,
    required this.verified,
    this.states = const <String>[],
    this.phone = '',
  });

  final String id;
  final String title;
  final String description;
  final List<String> needs;
  final List<String> states;
  final String url;
  final String phone;
  final String label;
  final String verified;
}
