import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile_service.dart';
import '../services/circle_service.dart';
import '../navigation/village_navigation_scope.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> with SingleTickerProviderStateMixin {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const blush = Color(0xFFF3E2DD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

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
  static const _circleMomentsKey = 'ask_the_village_circle_moments';
  static const _dismissedRemindersKey =
      'ask_the_village_dismissed_reminders';
  static const _dismissedActivityKey = 'ask_the_village_dismissed_activity';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final CircleService circleService = CircleService();
  final TextEditingController statusNoteController = TextEditingController();
  StreamSubscription<List<CircleRequest>>? requestSubscription;
  StreamSubscription<List<CirclePerson>>? memberSubscription;
  final Map<String, CircleRequest> requestByUid = {};
  String status = 'Available to listen';
  String sharedStatusNote = '';
  String myUsername = '';
  String? selectedNeed;
  final Set<int> completedReminders = {};
  final Set<int> dismissedReminders = {};
  final Set<int> dismissedActivity = {};
  final Set<String> sentRequests = {};
  final Set<String> heartedMoments = {};
  List<_ReachOut> myReachOuts = [];
  List<_CircleMessage> circleMessages = [];
  List<_CircleMoment> circleMoments = [];
  List<_CircleCandidate> incomingRequests = [];
  late final List<_CircleMember> circleMembers;
  late final AnimationController _orbitController;

  String _key(String base) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'signed_out';
    return '${base}_\$uid';
  }

  bool get _isTestCircle => Uri.base.queryParameters['testCircle'] == '1';

  List<_CircleMember> get _visibleCircleMembers {
    if (!_isTestCircle) return circleMembers;
    return const [
      _CircleMember('@MayaTest', 'M', Color(0xFFF0D9CF), 'Available to listen', true, 'test_maya', 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=240&q=85'),
      _CircleMember('@JordanTest', 'J', Color(0xFFDCE8D9), 'Quiet today', true, 'test_jordan', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=240&q=85'),
      _CircleMember('@ReneeTest', 'R', Color(0xFFE6DDF1), 'Available to listen', true, 'test_renee', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=240&q=85'),
      _CircleMember('@MarcusTest', 'M', Color(0xFFF5E6C8), 'I need support', true, 'test_marcus', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=240&q=85'),
      _CircleMember('@PriyaTest', 'P', Color(0xFFDDE9EB), 'Available to listen', true, 'test_priya', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=240&q=85'),
    ];
  }

  List<_CircleMoment> get _visibleCircleMoments {
    if (!_isTestCircle) return circleMoments;
    return [
      ...circleMoments,
      _CircleMoment(
        text: 'I started my new job today!',
        author: '@ReneeTest',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      _CircleMoment(
        text: 'I finally finished my certification.',
        author: '@JordanTest',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _CircleMoment(
        text: 'My daughter had the best first soccer game.',
        author: '@MayaTest',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  bool _isTestMember(_CircleMember member) =>
      member.uid?.startsWith('test_') ?? false;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    )..repeat();
    circleMembers = <_CircleMember>[];
    _loadStatus();
    _connectCircleData();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    final username = await ProfileService.currentUsername();
    if (!mounted) return;
    setState(() {
      myUsername = username?.trim() ?? '';
    });
  }

  void _connectCircleData() {
    requestSubscription = circleService.incomingRequests().listen(
      (requests) {
        if (!mounted) return;
        requestByUid
          ..clear()
          ..addEntries(
            requests.map((request) =>
                MapEntry(request.sender.uid, request)),
          );
        setState(() {
          incomingRequests = requests.map((request) {
            final username = request.sender.username;
            return _CircleCandidate(
              username,
              '@$username',
              username.isEmpty ? '?' : username[0].toUpperCase(),
              paleSage,
              request.sender.uid,
            );
          }).toList();
        });
      },
      onError: (_) {},
    );

    memberSubscription = circleService.members().listen(
      (people) {
        if (!mounted) return;
        setState(() {
          circleMembers = people.map((person) {
            final username = person.username;
            return _CircleMember(
              '@$username',
              username.isEmpty ? '?' : username[0].toUpperCase(),
              paleSage,
              person.status.isEmpty ? 'Connected' : person.status,
              true,
              person.uid,
              person.photoUrl,
            );
          }).toList();
        });
      },
      onError: (_) {},
    );
  }

  Future<void> _loadStatus() async {
    final savedStatus = await _preferences.getString(_key(_statusKey));
    final savedNote = await _preferences.getString(_key(_statusNoteKey));
    final savedReachOuts =
        await _preferences.getStringList(_key(_reachOutsKey)) ?? const [];
    final savedDismissedReminders =
        await _preferences.getStringList(_key(_dismissedRemindersKey)) ??
            const [];
    final savedDismissedActivity =
        await _preferences.getStringList(_key(_dismissedActivityKey)) ??
            const [];
    final savedCircleMessages =
        await _preferences.getStringList(_key(_circleMessagesKey)) ?? const [];
    final savedCircleMoments =
        await _preferences.getStringList(_key(_circleMomentsKey)) ?? const [];
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
    final loadedCircleMoments = <_CircleMoment>[];
    for (final item in savedCircleMoments) {
      try {
        loadedCircleMoments.add(
          _CircleMoment.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } on Object {
        // Keep the rest if one locally saved moment is damaged.
      }
    }
    loadedCircleMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      circleMoments = loadedCircleMoments;
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
    await _preferences.setString(_key(_statusKey), option);
    await _preferences.setString(_key(_statusNoteKey), '');
    try {
      await circleService.updateStatus(option);
    } on Object {
      // The status remains saved locally while offline.
    }
  }

  Future<void> _shareStatus() async {
    final note = statusNoteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a short status first.')),
      );
      return;
    }
    setState(() {
      sharedStatusNote = note;
      statusNoteController.clear();
    });
    await _preferences.setString(_key(_statusKey), status);
    await _preferences.setString(_key(_statusNoteKey), note);
    try {
      await circleService.updateStatus(note);
    } on Object {
      // The status remains saved locally while offline.
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shared with your Circle.')),
    );
  }

  @override
  void dispose() {
    requestSubscription?.cancel();
    memberSubscription?.cancel();
    statusNoteController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _saveDismissedItems() async {
    await _preferences.setStringList(
      _key(_dismissedRemindersKey),
      dismissedReminders.map((index) => index.toString()).toList(),
    );
    await _preferences.setStringList(
      _key(_dismissedActivityKey),
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
      _key(_reachOutsKey),
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

  Future<void> _openReachOut({required String audience}) async {
    final need = selectedNeed;
    if (need == null) return;
    final controller = TextEditingController();
    final sent = await showModalBottomSheet<_ReachOut>(
      context: context, isScrollControlled: true, backgroundColor: cream, showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(22, 4, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reach Out', style: GoogleFonts.playfairDisplay(color: sage, fontSize: 31, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(need, style: const TextStyle(color: gold, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded, color: sage, size: 19),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Sending privately to', style: TextStyle(fontSize: 11)),
                  Text(audience, style: const TextStyle(fontWeight: FontWeight.w800)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller, autofocus: true, minLines: 3, maxLines: 6, maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Add what would feel helpful (optional)…',
                filled: true, fillColor: Colors.white.withValues(alpha: .62),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, _ReachOut(type: need, message: controller.text.trim(), audience: audience, createdAt: DateTime.now())),
                style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.all(16)),
                icon: const Icon(Icons.favorite_outline_rounded),
                label: const Text('Send private reach-out'),
              ),
            ),
          ]),
        ),
      ),
    );
    controller.dispose();
    if (sent != null && mounted) {
      setState(() { selectedNeed = null; myReachOuts.insert(0, sent); });
      await _saveReachOuts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your reach-out was shared with ${sent.audience}.')),
      );
    }
  }

  Future<void> _saveCircleMessages() {
    return _preferences.setStringList(
      _key(_circleMessagesKey),
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
      if (member.uid != null && !_isTestMember(member)) {
        try {
          await circleService.sendMessage(
            recipient: CirclePerson(
              uid: member.uid!,
              username: member.name.replaceFirst('@', ''),
            ),
            text: sentMessage,
          );
        } on Object {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message saved, but it could not send. Try again.'),
            ),
          );
          return;
        }
      }
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
      if (member.uid != null && !_isTestMember(member)) {
        try {
          await circleService.sendMessage(
            recipient: CirclePerson(
              uid: member.uid!,
              username: member.name.replaceFirst('@', ''),
            ),
            text: checkIn,
          );
        } on Object {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in saved, but it could not send. Try again.'),
            ),
          );
          return;
        }
      }
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
    var messages = circleMessages
        .where((item) => item.memberName == member.name)
        .toList();
    if (member.uid != null && !_isTestMember(member)) {
      try {
        final remote = await circleService.messages(member.uid!).first;
        messages = remote
            .map(
              (message) => _CircleMessage(
                memberName: member.name,
                text: message.text,
                createdAt: message.createdAt,
                isMine:
                    message.senderUid == FirebaseAuth.instance.currentUser?.uid,
              ),
            )
            .toList();
        await circleService.markMessagesRead(member.uid!);
      } on Object {
        // Continue with this account's cached conversation while offline.
      }
    }
    const posts = <String>[];

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
                  backgroundImage: member.photoUrl.isEmpty
                      ? null
                      : NetworkImage(member.photoUrl),
                  child: member.photoUrl.isEmpty
                      ? Text(
                          member.initials,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
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
                              '${message.isMine ? 'You' : member.name} · '
                              '${_shortMessageDate(message.createdAt)}',
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
    CirclePerson? result;
    String? message;
    var searching = false;
    var sending = false;

    await showModalBottomSheet<void>(
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
                  'Find Your People',
                  style: GoogleFonts.playfairDisplay(
                    color: sage,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Enter their exact username, then send a Circle request.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search @username',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .62),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onSubmitted: (_) async {
                    setSheetState(() {
                      searching = true;
                      result = null;
                      message = null;
                    });
                    final found =
                        await circleService.findPerson(searchController.text);
                    if (!sheetContext.mounted) return;
                    setSheetState(() {
                      searching = false;
                      result = found;
                      message = found == null
                          ? 'No username found. Check the spelling.'
                          : null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: searching
                        ? null
                        : () async {
                            setSheetState(() {
                              searching = true;
                              result = null;
                              message = null;
                            });
                            final found = await circleService
                                .findPerson(searchController.text);
                            if (!sheetContext.mounted) return;
                            setSheetState(() {
                              searching = false;
                              result = found;
                              message = found == null
                                  ? 'No username found. Check the spelling.'
                                  : null;
                            });
                          },
                    style: FilledButton.styleFrom(backgroundColor: sage),
                    icon: searching
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search_rounded),
                    label: Text(searching ? 'Searching…' : 'Search'),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Center(child: Text(message!)),
                ],
                if (result != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: paleSage,
                      border: Border.all(color: line),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFFFE8BE),
                          child: Text(
                            result!.username.isEmpty
                                ? '?'
                                : result!.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            '@${result!.username}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: sending
                              ? null
                              : () async {
                                  setSheetState(() => sending = true);
                                  try {
                                    await circleService.sendRequest(result!);
                                    if (!sheetContext.mounted) return;
                                    setState(() {
                                      sentRequests.add('@${result!.username}');
                                    });
                                    setSheetState(() {
                                      sending = false;
                                      message = 'Circle request sent.';
                                    });
                                  } on CircleException catch (error) {
                                    if (!sheetContext.mounted) return;
                                    setSheetState(() {
                                      sending = false;
                                      message = error.message;
                                    });
                                  } on Object {
                                    if (!sheetContext.mounted) return;
                                    setSheetState(() {
                                      sending = false;
                                      message =
                                          'Could not send the request. Try again.';
                                    });
                                  }
                                },
                          child: Text(sending ? 'Sending…' : 'Add'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
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
        ),
      ),
    );
    searchController.dispose();
  }

  Future<void> _acceptRequest(_CircleCandidate person) async {
    final request = requestByUid[person.uid];
    if (request == null) return;
    try {
      await circleService.acceptRequest(request);
      if (!mounted) return;
      setState(() => incomingRequests.remove(person));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.username} joined your Circle.')),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not accept the request. Try again.')),
      );
    }
  }

  Future<void> _declineRequest(_CircleCandidate person) async {
    final request = requestByUid[person.uid];
    if (request == null) return;
    await circleService.declineRequest(request);
    if (!mounted) return;
    setState(() => incomingRequests.remove(person));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${person.username} request declined.')),
    );
  }

  Future<String?> _chooseSupportAudience() {
    final members = _visibleCircleMembers;
    return showModalBottomSheet<String>(
      context: context, backgroundColor: cream, showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Who needs to see this?',
              style: GoogleFonts.playfairDisplay(color: sage, fontSize: 29, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Choose your whole Circle or one person you trust.'),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(backgroundColor: paleSage, child: Icon(Icons.groups_2_outlined, color: sage)),
              title: const Text('My whole Circle', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Everyone in your private Circle'),
              trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
              onTap: () => Navigator.pop(sheetContext, 'My whole Circle'),
            ),
            const Divider(color: line),
            for (final member in members)
              ListTile(
                leading: CircleAvatar(backgroundColor: member.color, child: Text(member.initials, style: const TextStyle(color: ink, fontWeight: FontWeight.w800))),
                title: Text(member.name),
                subtitle: Text(member.status),
                trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                onTap: () => Navigator.pop(sheetContext, member.name),
              ),
          ]),
        ),
      ),
    );
  }

  Future<void> _startAskMyCircle() async {
    final need = await showModalBottomSheet<String>(
      context: context, backgroundColor: cream, showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What do you need?',
              style: GoogleFonts.playfairDisplay(color: sage, fontSize: 29, fontWeight: FontWeight.w600)),
            const Text('Choose the support that would feel helpful.'),
            const SizedBox(height: 12),
            for (final choice in supportChoices)
              Card(
                margin: const EdgeInsets.only(bottom: 8), elevation: 0,
                color: Colors.white.withValues(alpha: .62),
                shape: RoundedRectangleBorder(side: const BorderSide(color: line), borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Icon(choice.$1, color: gold),
                  title: Text(choice.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(choice.$3),
                  trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                  onTap: () => Navigator.pop(sheetContext, choice.$2),
                ),
              ),
          ]),
        ),
      ),
    );
    if (need == null || !mounted) return;
    final audience = await _chooseSupportAudience();
    if (audience == null || !mounted) return;
    setState(() => selectedNeed = need);
    await _openReachOut(audience: audience);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/welcome_branch.png',
                      height: 18,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'My Circle',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: sage,
                        fontSize: 48,
                        height: .95,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'REAL PEOPLE  •  DEEPER DAYS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gold,
                        fontSize: 9,
                        letterSpacing: 3.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _activeCircleLayout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newCircleLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _circleOrbit(),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .62),
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Text(
                'Start your Circle',
                style: GoogleFonts.playfairDisplay(
                  color: ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Invite the people you trust for private support and real check-ins.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _findPeople,
                  style: FilledButton.styleFrom(
                    backgroundColor: sage,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Invite your first person'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _privacyCard(),
      ],
    );
  }

  Widget _activeCircleLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _circleOrbit(),
        const SizedBox(height: 22),
        _sectionTitle(
          'How are you today?',
          'Choose the kind of support you can give or need.',
        ),
        const SizedBox(height: 10),
        _statusChoices(),
        const SizedBox(height: 28),
        _sectionTitle(
          'Good things happening',
          'Private wins shared by your Circle.',
        ),
        const SizedBox(height: 12),
        _momentsRow(),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _shareSomethingGood,
            style: FilledButton.styleFrom(
              backgroundColor: sage,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            icon: const Icon(Icons.celebration_outlined, size: 20),
            label: const Text('Share something good'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _startAskMyCircle,
                icon: const Icon(Icons.favorite_border_rounded, size: 19),
                label: const Text('Ask for support'),
                style: TextButton.styleFrom(foregroundColor: sage),
              ),
            ),
            Container(width: 1, height: 21, color: line),
            Expanded(
              child: TextButton.icon(
                onPressed: _openCheckOnSomeone,
                icon: const Icon(Icons.waving_hand_outlined, size: 19),
                label: const Text('Check in'),
                style: TextButton.styleFrom(foregroundColor: sage),
              ),
            ),
          ],
        ),
        if (_visibleCircleMembers.isNotEmpty || incomingRequests.isNotEmpty) ...[
          const SizedBox(height: 12),
          _moreCircleTools(),
        ],
      ],
    );
  }

  String get _circleDisplayName {
    if (_isTestCircle) return 'Ariel';
    final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName.split(RegExp(r'\s+')).first;
    final username = myUsername.trim().replaceFirst('@', '');
    return username.isEmpty ? 'You' : username;
  }

  Widget _circleOrbit() {
    final name = _circleDisplayName;
    final people = _visibleCircleMembers.take(5).toList();
    final moreCount = _isTestCircle
        ? 14
        : math.max(0, _visibleCircleMembers.length - people.length);

    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, _) {
        final turn = _orbitController.value * 2 * math.pi;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(310.0, 390.0);
            final centerX = width / 2;
            const centerY = 180.0;
            // Keep the orbit moving exactly as before, but give the center
            // message a clear lower pocket inside the ring.
            const ringRadius = 150.0;
            const outerDiameter = 64.0;
            const badgeSize = 78.0;

            // Six evenly spaced positions. The offset leaves the bottom-center
            // open for Ariel's name and the center message.
            const firstAngle = -math.pi / 3;
            double movingAngle(int index) =>
                firstAngle + (index * 2 * math.pi / 6) + turn;

            Offset positionFor(int index, double diameter) {
              final angle = movingAngle(index);
              return Offset(
                centerX + ringRadius * math.cos(angle) - diameter / 2,
                centerY + ringRadius * math.sin(angle) - diameter / 2,
              );
            }

            return Center(
              child: SizedBox(
                width: width,
                height: 344,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: centerX - ringRadius,
                      top: centerY - ringRadius,
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: _OrbitRingPainter(phase: turn),
                      ),
                    ),
                    if (people.isEmpty)
                      for (final index in const [0, 2, 3, 5])
                        Builder(
                          builder: (context) {
                            final point = positionFor(index, outerDiameter);
                            return Positioned(
                              left: point.dx,
                              top: point.dy,
                              child: _orbitAddAvatar(),
                            );
                          },
                        )
                    else
                      for (var index = 0; index < people.length; index++)
                        Builder(
                        builder: (context) {
                          // Reserve position 0 for the pink +more circle.
                          final point = positionFor(index + 1, outerDiameter);
                          final person = people[index];
                          return Positioned(
                            left: point.dx,
                            top: point.dy,
                            child: _orbitPerson(
                              person.initials,
                              person.name.replaceFirst('@', ''),
                              person.color,
                              person.photoUrl,
                              () => _openMemberProfile(person),
                            ),
                          );
                        },
                      ),
                    if (moreCount > 0)
                      Builder(
                        builder: (context) {
                          final point = positionFor(0, badgeSize);
                          return Positioned(
                            left: point.dx,
                            top: point.dy,
                            child: _orbitMorePeople(moreCount),
                          );
                        },
                      ),
                    // Keep the full center group optically balanced inside the orbit.
                    Positioned(
                      left: centerX - 62,
                      top: centerY - 78,
                      child: GestureDetector(
                        onTap: _startAskMyCircle,
                        child: _orbitYou(name),
                      ),
                    ),
                    Positioned(
                      left: centerX - 62,
                      top: 220,
                      child: SizedBox(
                        width: 124,
                        child: Column(
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                color: sage,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'AT THE CENTER\nTOGETHER IS BETTER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 7.2,
                                color: gold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.15,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(Icons.wb_sunny_outlined, size: 14, color: gold),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _orbitMorePeople(int count) {
    return Semantics(
      button: true,
      label: 'View $count more amazing people',
      child: InkWell(
        onTap: _showAllPeople,
        borderRadius: BorderRadius.circular(43),
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: blush,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+$count',
                style: GoogleFonts.playfairDisplay(
                  color: sage,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'AMAZING\nPEOPLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sage,
                  fontSize: 7.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              const Icon(Icons.favorite_border_rounded, color: gold, size: 13),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orbitYou(String name) {
    final initial = name.isEmpty ? 'Y' : name.substring(0, 1).toUpperCase();
    final photoUrl = _isTestCircle
        ? 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=320&q=85'
        : FirebaseAuth.instance.currentUser?.photoURL ?? '';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: gold),
      child: CircleAvatar(
        radius: 54,
        backgroundColor: sage,
        backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
        child: photoUrl.isEmpty
            ? Text(
                initial,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }

  Widget _orbitPerson(
    String initials,
    String name,
    Color color,
    String photoUrl,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(44),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: line, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x16000000), blurRadius: 7, offset: Offset(0, 3)),
            ],
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color,
            backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
            child: photoUrl.isEmpty
                ? Icon(Icons.person_rounded, color: sage.withValues(alpha: .78), size: 27)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _orbitAddAvatar() {
    return Semantics(
      button: true,
      label: 'Invite someone to your Circle',
      child: InkWell(
        onTap: _findPeople,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF4F0E7),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x12000000), blurRadius: 7, offset: Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Color(0xFF667769), size: 28),
        ),
      ),
    );
  }

  Widget _orbitAddSpot() {
    return InkWell(
      onTap: _findPeople,
      borderRadius: BorderRadius.circular(30),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFF4F0E7),
            child: Icon(Icons.add_rounded, color: Color(0xFF667769), size: 27),
          ),
          SizedBox(height: 4),
          SizedBox(
            width: 66,
            child: Text(
              'Add',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _momentsRow() {
    final moments = _visibleCircleMoments;
    if (moments.isEmpty) {
      return InkWell(
        onTap: _shareSomethingGood,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .58),
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFF7EDD7),
                child: Icon(Icons.auto_awesome_rounded, color: gold),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The good things will live here. Share the first one.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: sage),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _momentCard(moments[index]),
      ),
    );
  }

  String _momentKey(_CircleMoment moment) =>
      '${moment.author}|${moment.text}';

  _CircleMember? _memberForMoment(_CircleMoment moment) {
    for (final member in _visibleCircleMembers) {
      if (member.name.toLowerCase() == moment.author.toLowerCase()) return member;
    }
    return null;
  }

  Future<void> _openMomentActions(_CircleMoment moment) async {
    final member = _memberForMoment(moment);
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your private win.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Celebrate ${member.name}',
                style: GoogleFonts.playfairDisplay(color: ink, fontSize: 29, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('“${moment.text}”'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => heartedMoments.add(_momentKey(moment)));
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Heart sent to ${member.name}.')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: blush, foregroundColor: sage, padding: const EdgeInsets.all(15),
                  ),
                  icon: const Icon(Icons.favorite_rounded),
                  label: Text(heartedMoments.contains(_momentKey(moment)) ? 'Heart sent' : 'Send a heart'),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(sheetContext); _quickCheckIn(member); },
                  style: OutlinedButton.styleFrom(foregroundColor: sage, side: const BorderSide(color: sage), padding: const EdgeInsets.all(15)),
                  icon: const Icon(Icons.waving_hand_outlined),
                  label: const Text('Check in'),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(sheetContext); _messageMember(member); },
                  style: OutlinedButton.styleFrom(foregroundColor: sage, side: const BorderSide(color: line), padding: const EdgeInsets.all(15)),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _momentCard(_CircleMoment moment) {
    final hearted = heartedMoments.contains(_momentKey(moment));
    return InkWell(
      onTap: () => _openMomentActions(moment),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 205,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: moment.author == 'You' ? blush.withValues(alpha: .8) : paleSage,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(hearted ? Icons.favorite_rounded : Icons.celebration_outlined, color: hearted ? const Color(0xFFC56868) : gold, size: 22),
            const SizedBox(height: 8),
            Expanded(
              child: Text(moment.text, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.18),
              ),
            ),
            Text(
              hearted ? 'Heart sent • ${moment.author}' : moment.author == 'You' ? 'You • just now' : moment.author,
              style: const TextStyle(fontSize: 11, color: Color(0xFF667769)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareSomethingGood() async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(22, 6, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share something good',
              style: GoogleFonts.playfairDisplay(color: ink, fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            const Text('A win, a milestone, or a bright spot worth celebrating.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 180,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What happened?',
                filled: true,
                fillColor: Colors.white.withValues(alpha: .7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, controller.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: sage,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.celebration_outlined),
                label: const Text('Add to Circle Moments'),
              ),
            ),
          ],
        ),
      ),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final moment = _CircleMoment(
      text: text,
      author: 'You',
      createdAt: DateTime.now(),
    );
    setState(() => circleMoments.insert(0, moment));
    await _preferences.setStringList(
      _key(_circleMomentsKey),
      circleMoments.map((item) => jsonEncode(item.toJson())).toList(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to your Circle Moments.')),
    );
  }

  Future<void> _showAllPeople() {
    final controller = TextEditingController();
    var query = '';
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final visible = _visibleCircleMembers.where((person) {
            final searchable = '${person.name} ${person.status}'.toLowerCase();
            return searchable.contains(query.toLowerCase());
          }).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                22, 4, 22, 24 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * .68,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Everyone in your Circle',
                            style: GoogleFonts.playfairDisplay(
                              color: ink, fontSize: 28, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _findPeople,
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('Invite'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      onChanged: (value) => setSheetState(() => query = value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search your Circle',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .65),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: line),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('No one matches that search.'))
                          : ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final person = visible[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 3),
                                  leading: CircleAvatar(
                                    backgroundColor: person.color,
                                    backgroundImage: person.photoUrl.isEmpty
                                        ? null
                                        : NetworkImage(person.photoUrl),
                                    child: person.photoUrl.isEmpty
                                        ? Text(person.initials,
                                            style: const TextStyle(color: ink, fontWeight: FontWeight.w800))
                                        : null,
                                  ),
                                  title: Text(person.name.replaceFirst('@', '')),
                                  subtitle: Text(person.status),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    _openMemberProfile(person);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  Widget _myStatusStrip(String name, String profileStatus) {
    final initial = name.isEmpty ? 'Y' : name.substring(0, 1).toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: paleSage.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: sage,
                child: Text(initial,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
              ),
              Positioned(
                right: -1, bottom: -1,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D8E62),
                    shape: BoxShape.circle,
                    border: Border.all(color: paleSage, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 1),
                Text(profileStatus, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: sage, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit your status',
            onPressed: () => FocusScope.of(context).requestFocus(FocusNode()),
            icon: const Icon(Icons.edit_outlined, color: sage, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _peopleShelf(String name) {
    final people = circleMembers.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Your people',
            style: GoogleFonts.playfairDisplay(color: ink, fontSize: 28, fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton.icon(
            onPressed: _findPeople,
            style: TextButton.styleFrom(foregroundColor: sage),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Invite'),
          ),
        ]),
        const Text('The people you trust to show up.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF667769))),
        const SizedBox(height: 14),
        Row(children: [
          _personShelfItem(
            label: 'You',
            initials: name.isEmpty ? 'Y' : name.substring(0, 1).toUpperCase(),
            color: sage,
            status: _shortStatusLabel(),
            isYou: true,
          ),
          for (final person in people)
            _personShelfItem(
              label: person.name.replaceFirst('@', ''),
              initials: person.initials,
              color: person.color,
              status: person.status,
              onTap: () => _openMemberProfile(person),
            ),
          for (var i = people.length; i < 3; i++) _addPersonShelfItem(),
        ]),
      ],
    );
  }

  Widget _personShelfItem({
    required String label, required String initials, required Color color,
    required String status, bool isYou = false, VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 27, backgroundColor: color,
              child: Text(initials, style: TextStyle(
                color: isYou ? Colors.white : ink, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            Positioned(
              right: -1, bottom: -1,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D8E62), shape: BoxShape.circle,
                  border: Border.all(color: cream, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF667769))),
        ]),
      ),
    );
  }

  Widget _addPersonShelfItem() {
    return Expanded(
      child: InkWell(
        onTap: _findPeople,
        borderRadius: BorderRadius.circular(20),
        child: const Column(children: [
          CircleAvatar(
            radius: 27, backgroundColor: Color(0xFFF4F0E7),
            child: Icon(Icons.add_rounded, color: Color(0xFF667769), size: 25),
          ),
          SizedBox(height: 6),
          Text('Add', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text('', style: TextStyle(fontSize: 9.5)),
        ]),
      ),
    );
  }

  Widget _statusChoices() {
    const options = <(String, IconData)>[
      ('Available to listen', Icons.person_outline_rounded),
      ('Quiet today', Icons.dark_mode_outlined),
      ('I need support', Icons.favorite_border_rounded),
    ];
    return Row(children: [
      for (var index = 0; index < options.length; index++) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => _chooseStatus(options[index].$1),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
              decoration: BoxDecoration(
                color: status == options[index].$1 ? paleSage : Colors.white.withValues(alpha: .48),
                border: Border.all(
                  color: status == options[index].$1 ? sage : line,
                  width: status == options[index].$1 ? 1.8 : 1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(options[index].$2, color: sage, size: 21),
                const SizedBox(height: 5),
                Text(
                  switch (options[index].$1) {
                    'Available to listen' => 'Listen',
                    'Quiet today' => 'Quiet',
                    _ => 'Support',
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ]),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _checkOnSomeoneCard() {
    return InkWell(
      onTap: _openCheckOnSomeone,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: blush.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(children: [
          CircleAvatar(
            backgroundColor: Color(0xFFFFEEE8),
            child: Icon(Icons.favorite_border_rounded, color: sage),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check on someone', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text('A small reach-out can mean a lot.', style: TextStyle(fontSize: 12.5)),
            ],
          )),
          Icon(Icons.arrow_forward_rounded, color: sage),
        ]),
      ),
    );
  }

  Widget _trustedPeoplePanel() {
    final people = <_CircleMember>[...circleMembers.take(3)];
    final name = myUsername.isEmpty ? 'You' : myUsername;
    final hasOtherPeople = people.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your trusted people',
            style: GoogleFonts.playfairDisplay(
              color: ink,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'A small Circle. A big difference.',
            style: TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _myCircleProfile(name)),
              for (final person in people)
                Expanded(child: _trustedPerson(person)),
              ...List.generate(
                3 - people.length,
                (index) => Expanded(child: _emptyTrustedSpot()),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _findPeople,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(
                hasOtherPeople ? 'Add another person' : 'Add your first person',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: sage,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (!hasOtherPeople) ...[
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Family. Friends. Neighbors. Anyone you trust.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF667769),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.05,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _myCircleProfile(String name) {
    final initial = name.isEmpty ? 'Y' : name.substring(0, 1).toUpperCase();
    final profileStatus =
        sharedStatusNote.trim().isEmpty ? _shortStatusLabel() : sharedStatusNote.trim();
    return InkWell(
      onTap: () => _chooseStatus(status),
      borderRadius: BorderRadius.circular(28),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: sage,
                child: Text(
                  initial,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D8E62),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'You',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          Text(
            profileStatus,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: sage),
          ),
        ],
      ),
    );
  }

  String _shortStatusLabel() {
    return switch (status) {
      'Available to listen' => 'Available',
      'Quiet today' => 'Quiet today',
      _ => 'Needs support',
    };
  }

  Widget _emptyTrustedSpot() {
    return Semantics(
      button: true,
      label: 'Add a trusted person',
      child: InkWell(
        onTap: _findPeople,
        borderRadius: BorderRadius.circular(28),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFFFFAF1),
            child: Icon(
              Icons.add_rounded,
              color: Color(0xFF667769),
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _trustedPerson(_CircleMember person) {
    return InkWell(
      onTap: () => _openMemberProfile(person),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: person.color,
                child: Text(person.initials,
                    style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: person.available
                        ? const Color(0xFF5D8E62)
                        : const Color(0xFFB8B1A7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(person.name.replaceFirst('@', ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          Text(person.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: sage)),
        ],
      ),
    );
  }

  Widget _addTrustedPerson() => InkWell(
    onTap: _findPeople,
    borderRadius: BorderRadius.circular(16),
    child: const Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: paleSage,
          child: Icon(Icons.add_rounded, color: sage),
        ),
        SizedBox(height: 6),
        Text('Add', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        Text('someone', style: TextStyle(fontSize: 10.5, color: sage)),
      ],
    ),
  );

  void _openCheckOnSomeone() {
    final members = _visibleCircleMembers;
    if (members.isEmpty) {
      _findPeople();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who would you like to check in on?',
                style: GoogleFonts.playfairDisplay(
                  color: ink, fontSize: 25, fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text('Choose someone from your Circle.'),
              const SizedBox(height: 12),
              ...members.map(
                (member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: member.color,
                    backgroundImage: member.photoUrl.isEmpty
                        ? null
                        : NetworkImage(member.photoUrl),
                    child: member.photoUrl.isEmpty
                        ? Text(member.initials,
                            style: const TextStyle(color: ink, fontWeight: FontWeight.w800))
                        : null,
                  ),
                  title: Text(member.name.replaceFirst('@', '')),
                  subtitle: Text(member.status),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _quickCheckIn(member);
                  },
                ),
              ),
            ],
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No care reminders right now. Follow-ups from real Circle activity will appear here.',
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              'Circle activity',
              'Only updates people chose to share.',
            ),
            const SizedBox(height: 9),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No new Circle activity. Updates will appear when members choose to share them.',
              ),
            ),
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

class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ring = Paint()
      ..color = const Color(0xFFCDBB9A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    canvas.drawCircle(center, radius, ring);

    // Gold dots travel with the portraits along this same line.
    final dot = Paint()..color = const Color(0xFFB78943);
    for (var index = 0; index < 6; index++) {
      final angle = phase + (-math.pi / 3) + (index * 2 * math.pi / 6);
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        4,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) =>
      oldDelegate.phase != phase;
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
    this.color, [
    this.uid,
  ]);

  final String name;
  final String username;
  final String initials;
  final Color color;
  final String? uid;
}


class _CircleMessage {
  const _CircleMessage({
    required this.memberName,
    required this.text,
    required this.createdAt,
    this.isQuickCheckIn = false,
    this.isMine = true,
  });

  factory _CircleMessage.fromJson(Map<String, dynamic> json) {
    return _CircleMessage(
      memberName: json['memberName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isQuickCheckIn: json['isQuickCheckIn'] as bool? ?? false,
      isMine: json['isMine'] as bool? ?? true,
    );
  }

  final String memberName;
  final String text;
  final DateTime createdAt;
  final bool isQuickCheckIn;
  final bool isMine;

  Map<String, dynamic> toJson() => {
    'memberName': memberName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'isQuickCheckIn': isQuickCheckIn,
    'isMine': isMine,
  };
}

class _CircleMember {
  const _CircleMember(
    this.name,
    this.initials,
    this.color,
    this.status,
    this.available, [
    this.uid,
    this.photoUrl = '',
  ]);

  final String name;
  final String initials;
  final Color color;
  final String status;
  final bool available;
  final String? uid;
  final String photoUrl;
}


class _CircleMoment {
  const _CircleMoment({
    required this.text,
    required this.author,
    required this.createdAt,
  });

  final String text;
  final String author;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'text': text,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
      };

  factory _CircleMoment.fromJson(Map<String, dynamic> json) => _CircleMoment(
        text: json['text'] as String? ?? '',
        author: json['author'] as String? ?? 'You',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
