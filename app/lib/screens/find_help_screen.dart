import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  bool showMap = false;
  bool showAllResources = false;
  String? selectedPathId;

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

  static const helpPaths = <HelpPath>[
    HelpPath('food', 'Food or groceries', 'Find food pantries, meals, SNAP and grocery support.', Icons.restaurant_outlined, ['Food']),
    HelpPath('housing', 'Rent, bills or housing', 'Get help with rent, shelter, utilities and keeping your home.', Icons.home_outlined, ['Rent & Housing', 'Utilities']),
    HelpPath('family', 'Health, family or childcare', 'Find healthcare, childcare, transportation and family support.', Icons.favorite_border_rounded, ['Healthcare', 'Childcare', 'Transportation']),
    HelpPath('work', 'Work, legal or other support', 'Get connected to jobs, legal aid, safety planning and someone who can help.', Icons.handshake_outlined, ['Employment', 'Legal Help', 'Crisis & Safety']),
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
      id: 'state-social-services',
      title: 'State Benefits & Social Services',
      description: 'Find your state social service agency for SNAP, cash assistance, Medicaid, childcare help, and other state-run programs.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Employment'],
      url: 'https://www.usa.gov/state-social-services',
      label: 'Official government directory',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'emergency-food',
      title: 'Emergency Food Assistance',
      description: 'Find emergency food options, including food pantries, hunger hotlines, disaster food assistance, and local help.',
      needs: ['Food'],
      url: 'https://www.usa.gov/emergency-food-assistance',
      phone: '1-866-348-6479',
      label: 'Official • Nationwide',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'health-center',
      title: 'Find a Community Health Center',
      description: 'Search nearby health centers for medical, dental, behavioral-health, vision, and other care.',
      needs: ['Healthcare'],
      url: 'https://findahealthcenter.hrsa.gov/',
      label: 'Official • Local locator',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'childcare-referral',
      title: 'Child Care Resource & Referral Search',
      description: 'Find the local organization that helps families locate childcare, financial assistance, and family services.',
      needs: ['Childcare'],
      url: 'https://www.childcareaware.org/resources/ccrr-search/',
      label: 'Nationwide local locator',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'jobs-local',
      title: 'American Job Center Finder',
      description: 'Find nearby no-cost help with job searches, training, résumé support, workshops, computers, and employment services.',
      needs: ['Employment'],
      url: 'https://www.careeronestop.org/LocalHelp/AmericanJobCenters/find-american-job-centers.aspx',
      phone: '1-877-872-5627',
      label: 'Official • Local locator',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'legal-aid',
      title: 'Free Civil Legal Aid Finder',
      description: 'Search by address or city for nonprofit legal aid for housing, family, benefits, safety, consumer, and other civil matters.',
      needs: ['Legal Help'],
      url: 'https://www.lsc.gov/about-lsc/what-legal-aid/i-need-legal-help',
      label: 'Nationwide nonprofit network',
      verified: 'September 2026',
    ),
    HelpResource(
      id: '988',
      title: '988 Suicide & Crisis Lifeline',
      description: 'Free, confidential support for mental-health struggles, emotional distress, substance-use concerns, or a crisis. Call, text, or chat.',
      needs: ['Crisis & Safety','Healthcare'],
      url: 'https://988lifeline.org/get-help/',
      phone: '988',
      label: 'Free • 24/7',
      verified: 'September 2026',
    ),
    HelpResource(
      id: 'local-programs',
      title: 'Search Local Programs & Nonprofits',
      description: 'Enter your ZIP code below to search food pantries, rent help, bills, health care, transportation, job help, and other programs near you.',
      needs: ['Food','Rent & Housing','Utilities','Healthcare','Childcare','Transportation','Employment','Legal Help','Crisis & Safety'],
      url: 'https://www.findhelp.org/',
      label: 'Local nonprofit directory',
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

  List<HelpResource> _stateStartingPoints() {
    final state = selectedState;
    if (state == null) return const <HelpResource>[];
    final name = stateNames[state]!;
    return [
      HelpResource(
        id: 'local_food_$state',
        title: '$name food and grocery help',
        description: 'Find local food banks, groceries, SNAP guidance, meal programs, and other food support near you through 211.',
        needs: const ['Food'],
        states: [state],
        url: 'https://www.211.org/get-help/food-programs-food-benefits',
        phone: '211',
        label: 'Local help in $name',
        verified: 'September 2026',
      ),
      HelpResource(
        id: 'local_housing_$state',
        title: '$name rent, housing and utility help',
        description: 'Find local rent assistance, shelter, mortgage, utility-bill help, and housing-stability programs through 211.',
        needs: const ['Rent & Housing', 'Utilities'],
        states: [state],
        url: 'https://www.211.org/get-help/housing-expenses',
        phone: '211',
        label: 'Local help in $name',
        verified: 'September 2026',
      ),
      HelpResource(
        id: 'local_health_$state',
        title: '$name health, childcare and transportation help',
        description: 'Get connected with local medical-cost, medication, appointment transportation, childcare, and family-support options.',
        needs: const ['Healthcare', 'Childcare', 'Transportation'],
        states: [state],
        url: 'https://www.211.org/get-help/healthcare-expenses',
        phone: '211',
        label: 'Local help in $name',
        verified: 'September 2026',
      ),
      HelpResource(
        id: 'local_work_$state',
        title: '$name job, legal and crisis support',
        description: 'Talk with a local 211 specialist about employment, legal help, safety planning, and other urgent support.',
        needs: const ['Employment', 'Legal Help', 'Crisis & Safety'],
        states: [state],
        url: 'https://www.211.org/',
        phone: '211',
        label: 'Local help in $name',
        verified: 'September 2026',
      ),
    ];
  }

  HelpPath? get _selectedPath {
    for (final path in helpPaths) {
      if (path.id == selectedPathId) return path;
    }
    return null;
  }

  List<HelpResource> _applyNeed(List<HelpResource> items) {
    final path = _selectedPath;
    if (path != null) return items.where((resource) => resource.needs.any(path.needs.contains)).toList();
    if (selectedNeed == null) return items;
    return items.where((resource) => resource.needs.contains(selectedNeed)).toList();
  }

  List<HelpResource> _visible(List<HelpResource> managed) {
    final all = [...builtIns, ...managed];
    if (view == 2) return all.where((resource) => saved.contains(resource.id)).toList();

    if (selectedState != null) {
      final stateSpecific = all.where((resource) => resource.states.contains(selectedState)).toList();
      final local = _applyNeed([...stateSpecific, ..._stateStartingPoints()]);
      final nationwide = _applyNeed(all.where((resource) => resource.states.isEmpty).toList());
      return [...local, ...nationwide];
    }

    return _applyNeed(all);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ManagedContentItem>>(
      stream: admin.cloudReady ? admin.watchPublished('resources') : Stream.value(const <ManagedContentItem>[]),
      builder: (context, snapshot) {
        final managed = _managed(snapshot.data ?? const <ManagedContentItem>[]);
        final visible = _visible(managed);
        final localResults = selectedState == null || view == 2
            ? const <HelpResource>[]
            : visible.where((resource) => resource.states.contains(selectedState)).toList();
        final nationwideResults = selectedState == null || view == 2
            ? visible
            : visible.where((resource) => resource.states.isEmpty).toList();
        if (view == 1) return _courses(snapshot.data ?? const <ManagedContentItem>[]);
        if (view == 0 && selectedPathId == null) return _helpStart();
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
                ButtonSegment(value: 0, label: Text('Find Help'), icon: Icon(Icons.map_outlined)),
                ButtonSegment(value: 1, label: Text('Courses'), icon: Icon(Icons.auto_stories_outlined)),
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
            if (view == 0) ...[
              _selectedHelpHeader(),
              const SizedBox(height: 12),
              _zipSearch(),
              const SizedBox(height: 15),
              _stateBrowser(),
            ],
            if (view == 2) _savedHeader(),
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
            else if (selectedState != null && view != 2) ...[
              Text('Help in ${stateNames[selectedState]}', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 4),
              const Text('Local and state-specific options come first.', style: TextStyle(fontSize: 12, color: Color(0xFF626A63))),
              const SizedBox(height: 10),
              for (final resource in localResults) ...[
                _resourceCard(resource),
                const SizedBox(height: 11),
              ],
              if (nationwideResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Nationwide programs', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 4),
                const Text('More trusted options available across the country.', style: TextStyle(fontSize: 12, color: Color(0xFF626A63))),
                const SizedBox(height: 10),
                for (final resource in nationwideResults) ...[
                  _resourceCard(resource),
                  const SizedBox(height: 11),
                ],
              ],
            ] else ...[
              for (final resource in (showAllResources ? visible : visible.take(6))) ...[
                _resourceCard(resource),
                const SizedBox(height: 11),
              ],
              if (!showAllResources && visible.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => showAllResources = true),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text('See all ' + visible.length.toString() + ' resources'),
                    style: OutlinedButton.styleFrom(foregroundColor: sage, minimumSize: const Size.fromHeight(46)),
                  ),
                ),
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

  Future<void> _chooseState() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Text('States', style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 5),
              const Text('We will show statewide and nationwide help.'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: stateNames.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: line),
                  itemBuilder: (context, index) {
                    final entry = stateNames.entries.elementAt(index);
                    return ListTile(
                      leading: Container(
                        width: 38,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(9)),
                        child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900, color: sage)),
                      ),
                      title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: selectedState == entry.key ? const Icon(Icons.check_circle_rounded, color: sage) : const Icon(Icons.chevron_right_rounded, color: sage),
                      onTap: () => Navigator.pop(context, entry.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) setState(() => selectedState = choice);
  }

  Widget _map() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F0E8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined, color: gold, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Find help in your state', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink))),
                if (selectedState != null) TextButton(onPressed: () => setState(() => selectedState = null), child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _chooseState,
              borderRadius: BorderRadius.circular(17),
              child: AspectRatio(
                aspectRatio: 959 / 593,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: SvgPicture.asset(
                          'assets/images/us_states_map.svg',
                          fit: BoxFit.contain,
                          semanticsLabel: 'United States map showing state boundaries',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseState,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(selectedState == null ? 'Select a state' : stateNames[selectedState]!),
              style: OutlinedButton.styleFrom(
                foregroundColor: sage,
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: sage),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );

  Widget _courses(List<ManagedContentItem> managed) {
    final custom = managed
        .where((item) => item.data['course'] == true)
        .map((item) => SupportCourse(
              title: item.text('title', 'Village course'),
              description: item.text('description', item.text('body')),
              community: item.text('community', 'Village'),
              length: item.text('courseLength', 'Self-paced'),
              url: item.text('courseUrl', item.text('url')),
            ))
        .toList();
    const starter = <SupportCourse>[
      SupportCourse(title: 'Building a Stronger Relationship', description: 'A practical starting place for communicating better, reconnecting, and handling hard moments as a team.', community: 'Relationships', length: '4 short lessons'),
      SupportCourse(title: 'The Men’s Wellbeing Room', description: 'Guided conversations around pressure, emotional health, fatherhood, friendship, and purpose.', community: 'Men', length: '5 short lessons'),
      SupportCourse(title: 'Motherhood Without Losing Yourself', description: 'Support for identity, routines, asking for help, and caring for yourself while caring for everyone else.', community: 'Moms', length: '4 short lessons'),
      SupportCourse(title: 'Boundaries That Feel Like Care', description: 'Learn how to name your needs, hold healthy limits, and protect your peace without guilt.', community: 'Women', length: '3 short lessons'),
    ];
    final courses = [...custom, ...starter];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Find Help'), icon: Icon(Icons.map_outlined)),
            ButtonSegment(value: 1, label: Text('Courses'), icon: Icon(Icons.auto_stories_outlined)),
            ButtonSegment(value: 2, label: Text('Saved'), icon: Icon(Icons.bookmark_border_rounded)),
          ],
          selected: {view},
          onSelectionChanged: (value) => setState(() => view = value.first),
          style: ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(height: 15),
        Text('Learn & grow', style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 4),
        Text('Short, supportive courses made for the conversations happening in the Village.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF626A63))),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(18)),
          child: const Row(children: [
            Icon(Icons.auto_stories_outlined, color: sage),
            SizedBox(width: 10),
            Expanded(child: Text('Choose a topic that meets you where you are. New courses are added by the Village.', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
          ]),
        ),
        const SizedBox(height: 18),
        Text('Courses for your season', style: GoogleFonts.playfairDisplay(fontSize: 23, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 10),
        for (final course in courses) ...[
          _courseCard(course),
          const SizedBox(height: 11),
        ],
      ],
    );
  }

  Widget _courseCard(SupportCourse course) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 43, height: 43, decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.play_lesson_outlined, color: sage)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.community, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(course.title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
            ])),
          ]),
          const SizedBox(height: 10),
          Text(course.description, style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: ink)),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.schedule_outlined, size: 16, color: sage),
            const SizedBox(width: 5),
            Expanded(child: Text(course.length, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: sage))),
            if (course.url.isNotEmpty)
              FilledButton(onPressed: () => _open(course.url), style: FilledButton.styleFrom(backgroundColor: sage, visualDensity: VisualDensity.compact), child: const Text('Start'))
            else
              OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This course is coming soon.'))), style: OutlinedButton.styleFrom(foregroundColor: sage), child: const Text('Coming soon')),
          ]),
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

  Future<void> _showZipResults() async {
    final zip = zipController.text.trim();
    if (!RegExp(r'^\d{5}').hasMatch(zip)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a 5-digit ZIP code.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Help near ' + zip, style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 5),
              const Text('Choose the type of local support you want to search.', textAlign: TextAlign.center),
              const SizedBox(height: 14),
              _localSearchOption(
                sheetContext,
                icon: Icons.volunteer_activism_outlined,
                title: 'Programs & nonprofits',
                detail: 'Food, rent, bills, transportation, jobs, and more',
                onTap: () => _open('https://www.findhelp.org/search/text?postal=' + zip + '&term=individuals'),
              ),
              _localSearchOption(
                sheetContext,
                icon: Icons.support_agent_rounded,
                title: 'Talk to 211',
                detail: 'Speak with a local specialist about your situation',
                onTap: () => _call('211'),
              ),
              _localSearchOption(
                sheetContext,
                icon: Icons.local_hospital_outlined,
                title: 'Low-cost health care',
                detail: 'Find community health centers near ' + zip,
                onTap: () => _open('https://findahealthcenter.hrsa.gov/?incrementalsearch=true&radius=10&zip=' + zip),
              ),
              _localSearchOption(
                sheetContext,
                icon: Icons.gavel_outlined,
                title: 'Free legal aid',
                detail: 'Find nonprofit civil legal assistance',
                onTap: () => _open('https://www.lsc.gov/about-lsc/what-legal-aid/i-need-legal-help'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _localSearchOption(
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: sage),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(detail, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_rounded, color: sage),
          onTap: () {
            Navigator.pop(sheetContext);
            onTap();
          },
        ),
      );

  Widget _zipSearch() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sage,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.location_searching_rounded, color: Color(0xFFFFE4B4)),
              SizedBox(width: 8),
              Text('Start with where you live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 5),
            const Text('Enter a ZIP code to see real programs and nonprofits serving your area.', style: TextStyle(color: Color(0xFFE7EFE1), fontSize: 12, height: 1.35)),
            const SizedBox(height: 12),
            TextField(
              controller: zipController,
              keyboardType: TextInputType.number,
              maxLength: 5,
              decoration: InputDecoration(
                counterText: '',
                prefixIcon: const Icon(Icons.location_on_outlined, color: sage),
                hintText: 'Enter ZIP code',
                suffixIcon: TextButton(
                  onPressed: _showZipResults,
                  child: const Text('Search'),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      );

  Widget _needExplorer() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('What do you need help with?', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink))),
              if (selectedNeed != null)
                TextButton(onPressed: () => setState(() => selectedNeed = null), child: const Text('Clear')),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final need in needs)
                  ChoiceChip(
                    avatar: Icon(need.$2, size: 16, color: selectedNeed == need.$1 ? Colors.white : sage),
                    label: Text(need.$1),
                    selected: selectedNeed == need.$1,
                    onSelected: (_) => setState(() {
                      selectedNeed = selectedNeed == need.$1 ? null : need.$1;
                      showAllResources = false;
                    }),
                    selectedColor: sage,
                    labelStyle: TextStyle(color: selectedNeed == need.$1 ? Colors.white : ink, fontSize: 11, fontWeight: FontWeight.w700),
                    side: BorderSide(color: selectedNeed == need.$1 ? sage : line),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _helpStart() => ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Text('Get help, your way.', style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text('Start with what feels hardest right now. We will help you find the next step.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF626A63))),
          const SizedBox(height: 14),
          _urgentBanner(),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Find Help'), icon: Icon(Icons.map_outlined)),
              ButtonSegment(value: 1, label: Text('Courses'), icon: Icon(Icons.auto_stories_outlined)),
              ButtonSegment(value: 2, label: Text('Saved'), icon: Icon(Icons.bookmark_border_rounded)),
            ],
            selected: {view},
            onSelectionChanged: (value) => setState(() => view = value.first),
            style: ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 20),
          Text('What do you need help with?', style: GoogleFonts.playfairDisplay(fontSize: 23, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 5),
          const Text('You do not have to figure it all out alone.', style: TextStyle(fontSize: 12.5, color: Color(0xFF626A63))),
          const SizedBox(height: 12),
          for (final path in helpPaths) ...[
            _helpPathCard(path),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _chooseState,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Browse state programs instead'),
            style: TextButton.styleFrom(foregroundColor: sage),
          ),
        ],
      );

  Widget _helpPathCard(HelpPath path) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() {
          selectedPathId = path.id;
          selectedState = null;
          showAllResources = false;
        }),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(15)), child: Icon(path.icon, color: sage)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(path.title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 3),
              Text(path.detail, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF626A63))),
            ])),
            const Icon(Icons.arrow_forward_rounded, color: sage),
          ]),
        ),
      );

  Widget _selectedHelpHeader() {
    final path = _selectedPath!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Icon(path.icon, color: sage),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Looking for help with', style: TextStyle(fontSize: 11.5, color: Color(0xFF626A63))),
          Text(path.title, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: ink)),
        ])),
        TextButton(onPressed: () => setState(() {
          selectedPathId = null;
          selectedState = null;
          showAllResources = false;
        }), child: const Text('Change')),
      ]),
    );
  }

  Widget _stateBrowser() => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFFF4F0E8), borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.map_outlined, color: gold),
              const SizedBox(width: 9),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Browse help by state', style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: ink)),
                const Text('State benefits and programs come first.', style: TextStyle(fontSize: 11.5, color: Color(0xFF626A63))),
              ])),
              TextButton(
                onPressed: () => setState(() => showMap = !showMap),
                child: Text(showMap ? 'Hide map' : 'Open map'),
              ),
            ]),
            if (showMap) ...[
              const SizedBox(height: 12),
              _map(),
            ],
          ],
        ),
      );


  String _resultsTitle() {
    if (view == 2) return 'Saved resources';
    final path = _selectedPath;
    if (path != null) return 'Support for ' + path.title;
    if (selectedNeed != null) return selectedNeed!;
    if (selectedState != null) return 'Help in ' + (stateNames[selectedState] ?? '');
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

class HelpPath {
  const HelpPath(this.id, this.title, this.detail, this.icon, this.needs);
  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final List<String> needs;
}

class SupportCourse {
  const SupportCourse({
    required this.title,
    required this.description,
    required this.community,
    required this.length,
    this.url = '',
  });

  final String title;
  final String description;
  final String community;
  final String length;
  final String url;
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
