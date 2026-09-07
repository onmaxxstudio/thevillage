import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String status = 'Available to listen';
  String? selectedNeed;
  final Set<int> completedReminders = {};

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
    final sent = await showModalBottomSheet<bool>(
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
                    onPressed: () => Navigator.pop(sheetContext, true),
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

    if (sent == true && mounted) {
      setState(() => selectedNeed = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your reach-out was shared with $audience.')),
      );
    }
  }

  Future<void> _showInvite() async {
    const code = 'KIND-4821';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: Text(
          'Invite Someone You Trust',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this private invitation code. You approve every person before they join.',
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                code,
                style: TextStyle(
                  color: sage,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: code));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invitation code copied.')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy Code'),
          ),
        ],
      ),
    );
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
            tooltip: 'Invite someone',
            onPressed: _showInvite,
            icon: const Icon(Icons.person_add_alt_1_rounded, color: sage),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                _welcomeCard(),
                const SizedBox(height: 18),
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
                        onSelected: (_) => setState(() => status = option),
                        selectedColor: paleSage,
                        side: const BorderSide(color: line),
                        showCheckmark: false,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(
                  'Your people today',
                  '3 trusted people are available.',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) => _memberCard(members[index]),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(
                  'What do you need?',
                  'Choose the kind of support that would feel helpful.',
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  itemCount: supportChoices.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 112,
                  ),
                  itemBuilder: (_, index) {
                    final choice = supportChoices[index];
                    return _supportCard(
                      icon: choice.$1,
                      title: choice.$2,
                      subtitle: choice.$3,
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openReachOut,
                    style: FilledButton.styleFrom(
                      backgroundColor: sage,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.favorite_outline_rounded),
                    label: Text(
                      selectedNeed == null
                          ? 'Choose Support'
                          : 'Reach Out: $selectedNeed',
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                _sectionTitle(
                  'Care reminders',
                  'Small follow-ups can mean everything.',
                ),
                const SizedBox(height: 10),
                _reminderTile(
                  0,
                  'Check on Maya tonight',
                  'She asked for someone to listen.',
                ),
                const SizedBox(height: 9),
                _reminderTile(
                  1,
                  'Celebrate Jordan',
                  'They shared good news about a new job.',
                ),
                const SizedBox(height: 26),
                _sectionTitle(
                  'Circle activity',
                  'Only updates people chose to share.',
                ),
                const SizedBox(height: 10),
                _activityTile(
                  initials: 'NB',
                  color: const Color(0xFFD8C58F),
                  name: 'Nia',
                  update: 'Available to talk for the next hour.',
                  time: '12 min ago',
                ),
                const SizedBox(height: 9),
                _activityTile(
                  initials: 'JR',
                  color: const Color(0xFFAFC3A5),
                  name: 'Jordan',
                  update: 'Celebrating a small win today.',
                  time: '1 hr ago',
                ),
                const SizedBox(height: 18),
                _privacyCard(),
              ],
            ),
          ),
        ),
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

  Widget _memberCard(_CircleMember member) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(11),
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
                radius: 23,
                backgroundColor: member.color,
                child: Text(
                  member.initials,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
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
          const SizedBox(height: 6),
          Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(
            member.status,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5),
          ),
        ],
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
          ],
        ),
      ),
    );
  }

  Widget _activityTile({
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
