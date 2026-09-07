import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile_service.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const blush = Color(0xFFF3E2DD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  static const members = [
    _CircleMember('Maya', 'MS', Color(0xFFD9B8A8), 'Available to listen', true),
    _CircleMember('Jordan', 'JR', Color(0xFFAFC3A5), 'Free after 6 PM', true),
    _CircleMember('Nia', 'NB', Color(0xFFD8C58F), 'Can text now', true),
    _CircleMember('Cam', 'CW', Color(0xFFC7B5CF), 'Quiet day', false),
    _CircleMember('Avery', 'AL', Color(0xFFB7C8CE), 'At work', false),
  ];

  static const memberPosts = <String, List<String>>{
    'Maya': [
      'Some days support looks like listening without trying to fix it.',
      'Taking a quiet reset tonight and making room for rest.',
    ],
    'Jordan': [
      'A small check-in can change someone’s whole day.',
    ],
    'Nia': [
      'I have space to listen today if anyone needs a gentle conversation.',
      'Shared a reminder: asking for help is a form of strength.',
    ],
    'Cam': [
      'Choosing a quiet day and protecting my peace.',
    ],
    'Avery': [
      'Busy today, but I’ll check back in with the Circle later.',
    ],
  };

  static const searchablePeople = [
    _CircleCandidate('Aisha', '@AishaTalks', 'AT', Color(0xFFD6B8A7)),
    _CircleCandidate('Lena', '@LenaCares', 'LC', Color(0xFFB8C9A8)),
    _CircleCandidate('Rae', '@RaeListens', 'RL', Color(0xFFD5C18C)),
    _CircleCandidate('Tasha', '@TashaM', 'TM', Color(0xFFC9B8D4)),
  ];

  static const supportChoices = [
    (
      Icons.hearing_rounded,
      'Just listen',
      'I need a safe place to share.',
    ),
    (
      Icons.lightbulb_outline_rounded,
      'Give me advice',
      'I’d appreciate ideas or perspective.',
    ),
    (
      Icons.schedule_rounded,
      'Check on me later',
      'Please reach back out when you can.',
    ),
    (
      Icons.volunteer_activism_outlined,
      'Practical help',
      'I could use help with something specific.',
    ),
  ];

  static const statuses = [
    'Available to listen',
    'Quiet today',
    'I need support',
  ];

  static const _statusKey = 'ask_the_village_circle_status';
  static const _statusNoteKey = 'ask_the_village_circle_status_note';
  static const _reachOutsKey = 'ask_the_village_circle_reach_outs';
  static const _circleMessagesKey = 'ask_the_village_circle_messages';
  static const _dismissedRemindersKey =
      'ask_the_village_dismissed_reminders';
  static const _dismissedActivityKey = 'ask_the_village_dismissed_activity';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final TextEditingController statusNoteController = TextEditingController();
  String status = 'Available to listen';
  String sharedStatusNote = '';
  String? selectedNeed;
  final Set<int> completedReminders = {};
  final Set<int> dismissedReminders = {};
  final Set<int> dismissedActivity = {};
  final Set<String> sentRequests = {};
  List<_ReachOut> myReachOuts = [];
  List<_CircleMessage> circleMessages = [];
  final List<_CircleCandidate> incomingRequests = [
    const _CircleCandidate(
      'Monique',
      '@MoeSupport',
      'MS',
      Color(0xFFD9B8A8),
    ),
    const _CircleCandidate(
      'Sam',
      '@SamChecksIn',
      'SC',
      Color(0xFFB7C8CE),
    ),
  ];
  late final List<_CircleMember> circleMembers;

  @override
  void initState() {
    super.initState();
    circleMembers = List<_CircleMember>.of(members);
    _loadStatus();
    ProfileService.currentUsername();
  }

  Future<void> _loadStatus() async {
    final savedStatus = await _preferences.getString(_statusKey);
    final savedNote = await _preferences.getString(_statusNoteKey);
    final savedReachOuts =
        await _preferences.getStringList(_reachOutsKey) ?? const [];
    final savedDismissedReminders =
        await _preferences.getStringList(_dismissedRemindersKey) ?? const [];
    final savedDismissedActivity =
        await _preferences.getStringList(_dismissedActivityKey) ?? const [];
    final savedCircleMessages =
        await _preferences.getStringList(_circleMessagesKey) ?? const [];
    final loadedCircleMessages = <_CircleMessage>[];
    for (final item in savedCircleMessages) {
      try {
        loadedCircleMessages.add(
          _CircleMessage.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } on Object {
        // Keep the rest if one locally saved message is damaged.
      }
    }
    loadedCircleMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final loadedReachOuts = <_ReachOut>[];
    for (final item in savedReachOuts) {
      try {
        loadedReachOuts.add(
          _ReachOut.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } on Object {
        // Keep the rest if one locally saved request is damaged.
      }
    }
    loadedReachOuts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      if (savedStatus != null && statuses.contains(savedStatus)) {
        status = savedStatus;
      }
      sharedStatusNote = savedNote ?? '';
      statusNoteController.text = sharedStatusNote;
      myReachOuts = loadedReachOuts;
      circleMessages = loadedCircleMessages;
      dismissedReminders
        ..clear()
        ..addAll(
          savedDismissedReminders
              .map(int.tryParse)
              .whereType<int>(),
        );
      dismissedActivity
        ..clear()
        ..addAll(
          savedDismissedActivity
              .map(int.tryParse)
              .whereType<int>(),
        );
    });
  }

  Future<void> _chooseStatus(String option) async {
    setState(() {
      status = option;
      sharedStatusNote = '';
      statusNoteController.clear();
    });
    await _preferences.setString(_statusKey, option);
    await _preferences.setString(_statusNoteKey, '');
  }

  Future<void> _shareStatus() async {
    final note = statusNoteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a short status first.')),
      );
      return;
    }
    setState(() => sharedStatusNote = note);
    await _preferences.setString(_statusKey, status);
    await _preferences.setString(_statusNoteKey, note);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your status was shared with your circle.')),
    );
  }

  @override
  void dispose() {
    statusNoteController.dispose();
    super.dispose();
  }

  Future<void> _saveDismissedItems() async {
    await _preferences.setStringList(
      _dismissedRemindersKey,
      dismissedReminders.map((index) => index.toString()).toList(),
    );
    await _preferences.setStringList(
      _dismissedActivityKey,
      dismissedActivity.map((index) => index.toString()).toList(),
    );
  }

  Future<void> _dismissReminder(int index) async {
    setState(() => dismissedReminders.add(index));
    await _saveDismissedItems();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Care reminder removed.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => dismissedReminders.remove(index));
            _saveDismissedItems();
          },
        ),
      ),
    );
  }

  Future<void> _dismissActivity(int index) async {
    setState(() => dismissedActivity.add(index));
    await _saveDismissedItems();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Circle activity removed.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => dismissedActivity.remove(index));
            _saveDismissedItems();
          },
        ),
      ),
    );
  }

  Future<void> _saveReachOuts() {
    return _preferences.setStringList(
      _reachOutsKey,
      myReachOuts.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _toggleReachOut(int index) async {
    setState(() {
      myReachOuts[index] = myReachOuts[index].copyWith(
        completed: !myReachOuts[index].completed,
      );
    });
    await _saveReachOuts();
  }

  Future<void> _deleteReachOut(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Delete this reach-out?'),
        content: const Text(
          'This permanently removes it from My Reach-Outs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep It'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || index >= myReachOuts.length) return;
    setState(() => myReachOuts.removeAt(index));
    await _saveReachOuts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reach-out deleted.')),
    );
  }

  Future<void> _openReachOut() async {
    final need = selectedNeed;
    if (need == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose the kind of support you need.')),
      );
      return;
    }

    final controller = TextEditingController();
    var audience = 'My whole circle';
    final sent = await showModalBottomSheet<_ReachOut>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            4,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reach Out',
                  style: GoogleFonts.playfairDisplay(
                    color: sage,
                    fontSize: 31,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  need,
                  style: const TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Who should receive this?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in const [
                      'My whole circle',
                      'Choose one person',
                    ])
                      ChoiceChip(
                        label: Text(option),
                        selected: audience == option,
                        onSelected: (_) {
                          setSheetState(() => audience = option);
                        },
                        selectedColor: paleSage,
                        side: const BorderSide(color: line),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Add what would feel helpful (optional)…',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .62),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: sage, size: 17),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Shared only with the people you choose.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                        _ReachOut(
                          type: need,
                          message: controller.text.trim(),
                          audience: audience,
                          createdAt: DateTime.now(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: sage,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.favorite_outline_rounded),
                    label: const Text('Send Private Reach-Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();

    if (sent != null && mounted) {
      setState(() {
        selectedNeed = null;
        myReachOuts.insert(0, sent);
      });
      await _saveReachOuts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your reach-out was shared with ${sent.audience}.')),
      );
    }
  }

  Future<void> _saveCircleMessages() {
    return _preferences.setStringList(
      _circleMessagesKey,
      circleMessages.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _messageMember(_CircleMember member) async {
    final controller = TextEditingController();
    final sentMessage = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          4,
          22,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Message ${member.name}',
                style: GoogleFonts.playfairDisplay(
                  color: sage,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Send a calm, private message to someone you trust.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Write your message…',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .65),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: sage, size: 17),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Only you and this Circle member can see this message.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final message = controller.text.trim();
                    if (message.isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Write a message first.')),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext, message);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: sage,
                    padding: const EdgeInsets.all(15),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Private Message'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();

    if (sentMessage != null && mounted) {
      setState(() {
        circleMessages.insert(
          0,
          _CircleMessage(
            memberName: member.name,
            text: sentMessage,
            createdAt: DateTime.now(),
          ),
        );
      });
      await _saveCircleMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Private message sent to ${member.name}.')),
      );
    }
  }

  Future<void> _quickCheckIn(_CircleMember member) async {
    final checkIn = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Check-In',
                style: GoogleFonts.playfairDisplay(
                  color: sage,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text('Send ${member.name} a gentle one-tap message.'),
              const SizedBox(height: 12),
              for (final option in const [
                ('Thinking of you', Icons.favorite_outline_rounded),
                ('How are you doing?', Icons.waving_hand_outlined),
                ('Do you need anything?', Icons.volunteer_activism_outlined),
              ])
                Card(
                  color: Colors.white.withValues(alpha: .62),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: line),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Icon(option.$2, color: sage),
                    title: Text(
                      option.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: const Icon(Icons.send_rounded, size: 18),
                    onTap: () => Navigator.pop(sheetContext, option.$1),
                  ),
                ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: sage, size: 16),
                  SizedBox(width: 6),
                  Text('Private to this Circle member.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (checkIn != null && mounted) {
      setState(() {
        circleMessages.insert(
          0,
          _CircleMessage(
            memberName: member.name,
            text: checkIn,
            createdAt: DateTime.now(),
            isQuickCheckIn: true,
          ),
        );
      });
      await _saveCircleMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“$checkIn” sent privately to ${member.name}.'),
        ),
      );
    }
  }

  String _shortMessageDate(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year &&
        now.month == date.month &&
        now.day == date.day) {
      final hour = date.hour == 0
          ? 12
          : date.hour > 12
              ? date.hour - 12
              : date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today · $hour:$minute $period';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _openMemberProfile(_CircleMember member) async {
    final messages = circleMessages
        .where((item) => item.memberName == member.name)
        .toList();
    final posts = memberPosts[member.name] ?? const <String>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .55,
        maxChildSize: .94,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: member.color,
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.playfairDisplay(
                          color: sage,
                          fontSize: 29,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(member.status),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline_rounded, color: sage, size: 19),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _messageMember(member);
                    },
                    style: FilledButton.styleFrom(backgroundColor: sage),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _quickCheckIn(member);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: sage,
                      side: const BorderSide(color: sage),
                    ),
                    icon: const Icon(Icons.favorite_outline_rounded),
                    label: const Text('Check In'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text(
              'Messages between you',
              style: GoogleFonts.playfairDisplay(
                color: ink,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Private conversation history',
              style: TextStyle(color: Color(0xFF687067), fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (messages.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .55),
                  border: Border.all(color: line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No messages yet. Send a message or a gentle check-in.',
                ),
              )
            else
              for (final message in messages.take(5))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: message.isQuickCheckIn
                        ? const Color(0xFFFFF3E4)
                        : paleSage,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        message.isQuickCheckIn
                            ? Icons.favorite_outline_rounded
                            : Icons.chat_bubble_outline_rounded,
                        color: message.isQuickCheckIn ? gold : sage,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: const TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'You · ${_shortMessageDate(message.createdAt)}',
                              style: const TextStyle(fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 22),
            Text(
              'Posts shared by ${member.name}',
              style: GoogleFonts.playfairDisplay(
                color: ink,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Circle-only posts appear here—no likes or popularity counts.',
              style: TextStyle(color: Color(0xFF687067), fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (posts.isEmpty)
              const Text('No Circle posts shared yet.')
            else
              for (final post in posts)
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .62),
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(post),
                ),
          ],
        ),
      ),
    );
  }


  Future<void> _findPeople() async {
    final searchController = TextEditingController();
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final normalized = query.trim().toLowerCase();
          final results = normalized.isEmpty
              ? <_CircleCandidate>[]
              : searchablePeople.where((person) {
                  return person.username.toLowerCase().contains(normalized) ||
                      person.name.toLowerCase().contains(normalized);
                }).toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              4,
              22,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Your People',
                    style: GoogleFonts.playfairDisplay(
                      color: sage,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Search by exact username, then send a Circle request.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (value) {
                      setSheetState(() => query = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search @username',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .62),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (normalized.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Enter a username to find someone.'),
                      ),
                    )
                  else if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No username found. Check the spelling.'),
                      ),
                    )
                  else
                    for (final person in results) ...[
                      Builder(
                        builder: (_) {
                          final requested =
                              sentRequests.contains(person.username);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .62),
                              border: Border.all(color: line),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: person.color,
                                  child: Text(
                                    person.initials,
                                    style: const TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(person.username),
                                    ],
                                  ),
                                ),
                                FilledButton(
                                  onPressed: requested
                                      ? null
                                      : () {
                                          setState(() {
                                            sentRequests.add(person.username);
                                          });
                                          setSheetState(() {});
                                        },
                                  child: Text(
                                    requested ? 'Requested' : 'Add',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: sage, size: 17),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'They join your Circle only after accepting.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    searchController.dispose();
  }

  void _acceptRequest(_CircleCandidate person) {
    setState(() {
      incomingRequests.remove(person);
      circleMembers.add(
        _CircleMember(
          person.name,
          person.initials,
          person.color,
          'New to your circle',
          true,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${person.username} joined your Circle.')),
    );
  }

  void _declineRequest(_CircleCandidate person) {
    setState(() => incomingRequests.remove(person));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${person.username} request declined.')),
    );
  }

  Future<void> _startAskMyCircle() async {
    final need = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you need?',
                style: GoogleFonts.playfairDisplay(
                  color: sage,
                  fontSize: 29,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text('Choose the support that would feel helpful.'),
              const SizedBox(height: 12),
              for (final choice in supportChoices)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: Colors.white.withValues(alpha: .62),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: Icon(choice.$1, color: gold),
                    title: Text(
                      choice.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(choice.$3),
                    trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                    onTap: () => Navigator.pop(sheetContext, choice.$2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (need == null || !mounted) return;
    setState(() => selectedNeed = need);
    await _openReachOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'My Circle',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 29,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Search usernames',
            onPressed: _findPeople,
            icon: const Icon(Icons.person_search_rounded, color: sage),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
              children: [
                _sectionTitle(
                  'How are you showing up?',
                  'Let your circle know what you have space for today.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in statuses)
                      ChoiceChip(
                        label: Text(option),
                        selected: status == option,
                        onSelected: (_) => _chooseStatus(option),
                        selectedColor: paleSage,
                        side: const BorderSide(color: line),
                        showCheckmark: false,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: statusNoteController,
                  maxLength: 70,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _shareStatus(),
                  decoration: InputDecoration(
                    labelText: 'Write your status',
                    hintText: 'Example: Can text after 6 PM',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .58),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Share status',
                      onPressed: _shareStatus,
                      icon: const Icon(Icons.send_rounded, color: sage),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _sectionTitle(
                  'Your trusted people',
                  'Tap a person for messages, check-ins and shared posts.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 138,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: circleMembers.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: ProfileService.usernameNotifier,
                          builder: (context, username, _) {
                            final cleanUsername = username?.trim() ?? '';
                            final displayUsername = cleanUsername.isEmpty
                                ? '@username'
                                : '@$cleanUsername';
                            final initials = cleanUsername.isEmpty
                                ? '?'
                                : cleanUsername.substring(0, 1).toUpperCase();
                            return _memberCard(
                              _CircleMember(
                                displayUsername,
                                initials,
                                paleSage,
                                sharedStatusNote.isEmpty
                                    ? status
                                    : sharedStatusNote,
                                status != 'Quiet today',
                              ),
                              isSelf: true,
                            );
                          },
                        );
                      }
                      return _memberCard(circleMembers[index - 1]);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _startAskMyCircle,
                    style: FilledButton.styleFrom(
                      backgroundColor: sage,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.favorite_outline_rounded),
                    label: const Text(
                      'Ask My Circle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: sage, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Only accepted Circle members can see it.',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _recentConnections(),
                const SizedBox(height: 18),
                _moreCircleTools(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recentConnections() {
    final recent = circleMessages.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Recent connection',
          'Your newest private messages and check-ins.',
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .58),
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Text(
              'No private history yet. Tap someone above to connect.',
            ),
          )
        else
          for (final message in recent)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: message.isQuickCheckIn
                    ? const Color(0xFFFFF3E4)
                    : Colors.white.withValues(alpha: .62),
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: message.isQuickCheckIn ? blush : paleSage,
                    child: Icon(
                      message.isQuickCheckIn
                          ? Icons.favorite_outline_rounded
                          : Icons.chat_bubble_outline_rounded,
                      color: message.isQuickCheckIn ? gold : sage,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.memberName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          message.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _shortMessageDate(message.createdAt),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _moreCircleTools() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .46),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          leading: const CircleAvatar(
            backgroundColor: paleSage,
            child: Icon(Icons.grid_view_rounded, color: sage),
          ),
          title: const Text(
            'More Circle tools',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            incomingRequests.isEmpty
                ? 'Reach-outs, reminders and activity'
                : '${incomingRequests.length} request${incomingRequests.length == 1 ? '' : 's'} waiting',
          ),
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _findPeople,
                icon: const Icon(Icons.person_search_rounded),
                label: const Text('Find People by Username'),
              ),
            ),
            if (incomingRequests.isNotEmpty) ...[
              const SizedBox(height: 18),
              _sectionTitle(
                'Circle requests',
                'Accept only people you trust.',
              ),
              const SizedBox(height: 9),
              for (final person in incomingRequests) ...[
                _requestTile(person),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 18),
            _sectionTitle(
              'My Reach-Outs',
              'Requests you shared with your Circle.',
            ),
            const SizedBox(height: 9),
            if (myReachOuts.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No active reach-outs.'),
              )
            else
              for (var index = 0;
                  index < myReachOuts.length;
                  index++) ...[
                _reachOutCard(index, myReachOuts[index]),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 18),
            _sectionTitle(
              'Care reminders',
              'Small follow-ups can mean everything.',
            ),
            const SizedBox(height: 9),
            if (dismissedReminders.length == 2)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No care reminders right now.'),
              )
            else ...[
              if (!dismissedReminders.contains(0))
                _reminderTile(
                  0,
                  'Check on Maya tonight',
                  'She asked for someone to listen.',
                ),
              if (!dismissedReminders.contains(0) &&
                  !dismissedReminders.contains(1))
                const SizedBox(height: 8),
              if (!dismissedReminders.contains(1))
                _reminderTile(
                  1,
                  'Celebrate Jordan',
                  'They shared good news about a new job.',
                ),
            ],
            const SizedBox(height: 18),
            _sectionTitle(
              'Circle activity',
              'Only updates people chose to share.',
            ),
            const SizedBox(height: 9),
            if (dismissedActivity.length == 2)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No new Circle activity.'),
              )
            else ...[
              if (!dismissedActivity.contains(0))
                _activityTile(
                  index: 0,
                  initials: 'NB',
                  color: const Color(0xFFD8C58F),
                  name: 'Nia',
                  update: 'Available to talk for the next hour.',
                  time: '12 min ago',
                ),
              if (!dismissedActivity.contains(0) &&
                  !dismissedActivity.contains(1))
                const SizedBox(height: 8),
              if (!dismissedActivity.contains(1))
                _activityTile(
                  index: 1,
                  initials: 'JR',
                  color: const Color(0xFFAFC3A5),
                  name: 'Jordan',
                  update: 'Celebrating a small win today.',
                  time: '1 hr ago',
                ),
            ],
            const SizedBox(height: 16),
            _privacyCard(),
          ],
        ),
      ),
    );
  }

  Widget _reachOutCard(int index, _ReachOut reachOut) {
    final date =
        '${reachOut.createdAt.month}/${reachOut.createdAt.day}/${reachOut.createdAt.year}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reachOut.completed
            ? paleSage.withValues(alpha: .72)
            : const Color(0xFFFFF6E8),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: reachOut.completed ? paleSage : blush,
                child: Icon(
                  reachOut.completed
                      ? Icons.check_rounded
                      : Icons.volunteer_activism_outlined,
                  color: sage,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reachOut.type,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: reachOut.completed ? Colors.white : paleSage,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reachOut.completed ? 'Complete' : 'Waiting for replies',
                  style: const TextStyle(
                    color: sage,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (reachOut.message.isNotEmpty) ...[
            Text(reachOut.message),
            const SizedBox(height: 7),
          ],
          Text(
            '${reachOut.audience}  •  $date',
            style: const TextStyle(fontSize: 11.5),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _deleteReachOut(index),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Delete'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _toggleReachOut(index),
                icon: Icon(
                  reachOut.completed
                      ? Icons.refresh_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 17,
                ),
                label: Text(
                  reachOut.completed ? 'Reopen' : 'Mark Complete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestTile(_CircleCandidate person) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: person.color,
            child: Text(
              person.initials,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  person.username,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Decline request',
            onPressed: () => _declineRequest(person),
            icon: const Icon(Icons.close_rounded),
          ),
          FilledButton(
            onPressed: () => _acceptRequest(person),
            style: FilledButton.styleFrom(backgroundColor: sage),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFFFE8BE),
            child: Icon(Icons.groups_2_rounded, color: sage, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your people. Your pace.',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Ask clearly, show up gently, and stay connected.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: ink,
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(subtitle, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }

  Widget _memberCard(_CircleMember member, {bool isSelf = false}) {
    return InkWell(
      onTap: isSelf ? null : () => _openMemberProfile(member),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 136,
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .58),
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: member.color,
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: member.available
                          ? const Color(0xFF5D8E62)
                          : const Color(0xFFB8B1A7),
                      shape: BoxShape.circle,
                      border: Border.all(color: cream, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              member.status,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5),
            ),
            const Spacer(),
            if (isSelf)
              const Text(
                'Your status',
                style: TextStyle(
                  color: sage,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Message ${member.name}',
                    onPressed: () => _messageMember(member),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 30,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: sage,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Quick check-in with ${member.name}',
                    onPressed: () => _quickCheckIn(member),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 30,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.favorite_outline_rounded,
                      color: gold,
                      size: 19,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _supportCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = selectedNeed == title;
    return InkWell(
      onTap: () => setState(() => selectedNeed = title),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? paleSage : Colors.white.withValues(alpha: .58),
          border: Border.all(
            color: selected ? sage : line,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? sage : gold, size: 25),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderTile(int index, String title, String subtitle) {
    final completed = completedReminders.contains(index);
    return InkWell(
      onTap: () {
        setState(() {
          completed ? completedReminders.remove(index) : completedReminders.add(index);
        });
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: completed ? paleSage : const Color(0xFFFFF6E8),
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.notifications_active_outlined,
              color: completed ? sage : gold,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete reminder',
              onPressed: () => _dismissReminder(index),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTile({
    required int index,
    required String initials,
    required Color color,
    required String name,
    required String update,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .58),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(update),
                const SizedBox(height: 3),
                Text(time, style: const TextStyle(fontSize: 10.5)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Send support',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('A little support was sent to $name.')),
              );
            },
            icon: const Icon(Icons.favorite_border_rounded, color: sage),
          ),
          IconButton(
            tooltip: 'Delete activity',
            onPressed: () => _dismissActivity(index),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: blush.withValues(alpha: .65),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: sage),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your Circle is private. You approve members and choose what each person can see.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReachOut {
  const _ReachOut({
    required this.type,
    required this.message,
    required this.audience,
    required this.createdAt,
    this.completed = false,
  });

  final String type;
  final String message;
  final String audience;
  final DateTime createdAt;
  final bool completed;

  Map<String, Object> toJson() => {
        'type': type,
        'message': message,
        'audience': audience,
        'createdAt': createdAt.toIso8601String(),
        'completed': completed,
      };

  factory _ReachOut.fromJson(Map<String, dynamic> json) {
    return _ReachOut(
      type: json['type'] as String? ?? 'Support request',
      message: json['message'] as String? ?? '',
      audience: json['audience'] as String? ?? 'My whole circle',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completed: json['completed'] as bool? ?? false,
    );
  }

  _ReachOut copyWith({bool? completed}) {
    return _ReachOut(
      type: type,
      message: message,
      audience: audience,
      createdAt: createdAt,
      completed: completed ?? this.completed,
    );
  }
}

class _CircleCandidate {
  const _CircleCandidate(
    this.name,
    this.username,
    this.initials,
    this.color,
  );

  final String name;
  final String username;
  final String initials;
  final Color color;
}


class _CircleMessage {
  const _CircleMessage({
    required this.memberName,
    required this.text,
    required this.createdAt,
    this.isQuickCheckIn = false,
  });

  factory _CircleMessage.fromJson(Map<String, dynamic> json) {
    return _CircleMessage(
      memberName: json['memberName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isQuickCheckIn: json['isQuickCheckIn'] as bool? ?? false,
    );
  }

  final String memberName;
  final String text;
  final DateTime createdAt;
  final bool isQuickCheckIn;

  Map<String, dynamic> toJson() => {
    'memberName': memberName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'isQuickCheckIn': isQuickCheckIn,
  };
}

class _CircleMember {
  const _CircleMember(
    this.name,
    this.initials,
    this.color,
    this.status,
    this.available,
  );

  final String name;
  final String initials;
  final Color color;
  final String status;
  final bool available;
}
